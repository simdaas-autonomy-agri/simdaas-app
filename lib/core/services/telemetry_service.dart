import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'ws_channel_stub.dart'
    if (dart.library.io) 'ws_channel_io.dart'
    if (dart.library.html) 'ws_channel_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/mac_utils.dart';

class TelemetryData {
  final String deviceId;
  final DateTime timestamp;
  final int? gpsSignalQuality;
  final int? simSignalQuality;
  final double? lat;
  final double? lon;
  final double? leftDistance;
  final double? rightDistance;
  final double? leftDensity;
  final double? rightDensity;
  final double? speed;
  final double? flowRate;
  final int? leftSolenoidState;
  final int? rightSolenoidState;
  final int? sprayMode;
  final double? tankLevel;
  final int? ptoState;
  final double? jobCompletionPercent;
  final String? plot;
  final bool? deviceInPlot;

  TelemetryData({
    required this.deviceId,
    required this.timestamp,
    this.gpsSignalQuality,
    this.simSignalQuality,
    this.lat,
    this.lon,
    this.leftDistance,
    this.rightDistance,
    this.leftDensity,
    this.rightDensity,
    this.speed,
    this.flowRate,
    this.leftSolenoidState,
    this.rightSolenoidState,
    this.sprayMode,
    this.tankLevel,
    this.ptoState,
    this.jobCompletionPercent,
    this.plot,
    this.deviceInPlot,
  });

  /// Parse telemetry JSON. Returns null when required fields (device_id
  /// and a parseable timestamp) are missing to avoid treating malformed
  /// messages as "active" (previously defaulted to now).
  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    // device id (support multiple common keys)
    final rawId = json['device_id'] ??
        json['deviceId'] ??
        json['id'] ??
        json['mac'] ??
        json['mac_address'];
    final deviceId = rawId?.toString().trim() ?? '';
    if (deviceId.isEmpty) throw FormatException('missing device_id');

    DateTime? ts;
    // try multiple common timestamp keys
    final cand = json['timestamp'] ?? json['ts'] ?? json['time'] ?? json['t'];
    if (cand != null) {
      // accept numeric epoch (seconds or milliseconds) or ISO strings
      try {
        if (cand is num) {
          // cand may be int or double
          final n = cand.toDouble();
          final ms = n > 1000000000000 ? n.toInt() : (n * 1000).toInt();
          ts = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
        } else {
          final s = cand.toString();
          // try parse as a floating numeric string first (e.g. "1763401570.0")
          final asNum = double.tryParse(s);
          if (asNum != null) {
            final ms =
                asNum > 1000000000000 ? asNum.toInt() : (asNum * 1000).toInt();
            ts = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
          } else {
            // fallback to ISO date parsing; treat parsed instants as UTC
            try {
              final parsed = DateTime.parse(s);
              ts = parsed.toUtc();
            } catch (_) {
              ts = null;
            }
          }
        }
      } catch (_) {
        ts = null;
      }
    }
    if (ts == null) throw FormatException('invalid timestamp');

    return TelemetryData(
      deviceId: deviceId,
      timestamp: ts,
      gpsSignalQuality: json['gps_signal_quality'] is int
          ? json['gps_signal_quality']
          : (json['gps_signal_quality'] != null
              ? int.tryParse(json['gps_signal_quality'].toString())
              : null),
      simSignalQuality: json['sim_signal_quality'] is int
          ? json['sim_signal_quality']
          : (json['sim_signal_quality'] != null
              ? int.tryParse(json['sim_signal_quality'].toString())
              : null),
      lat: json['lat'] is num ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] is num ? (json['lon'] as num).toDouble() : null,
      leftDistance: json['left_distance'] is num
          ? (json['left_distance'] as num).toDouble()
          : null,
      rightDistance: json['right_distance'] is num
          ? (json['right_distance'] as num).toDouble()
          : null,
      leftDensity: json['left_density'] is num
          ? (json['left_density'] as num).toDouble()
          : null,
      rightDensity: json['right_density'] is num
          ? (json['right_density'] as num).toDouble()
          : null,
      speed: json['speed'] is num ? (json['speed'] as num).toDouble() : null,
      flowRate: json['flow_rate'] is num
          ? (json['flow_rate'] as num).toDouble()
          : null,
      leftSolenoidState: json['left_solenoid_state'] is int
          ? json['left_solenoid_state']
          : (json['left_solenoid_state'] != null
              ? int.tryParse(json['left_solenoid_state'].toString())
              : null),
      rightSolenoidState: json['right_solenoid_state'] is int
          ? json['right_solenoid_state']
          : (json['right_solenoid_state'] != null
              ? int.tryParse(json['right_solenoid_state'].toString())
              : null),
      sprayMode: json['spray_mode'] is int
          ? json['spray_mode']
          : (json['spray_mode'] != null
              ? int.tryParse(json['spray_mode'].toString())
              : null),
      tankLevel: json['tank_level'] is num
          ? (json['tank_level'] as num).toDouble()
          : null,
      ptoState: json['pto_state'] is int
          ? json['pto_state']
          : (json['pto_state'] != null
              ? int.tryParse(json['pto_state'].toString())
              : null),
      jobCompletionPercent: json['job_completion_percent'] is num
          ? (json['job_completion_percent'] as num).toDouble()
          : null,
      plot: json['plot']?.toString(),
      deviceInPlot: json['device_in_plot'] is bool
          ? json['device_in_plot']
          : (json['device_in_plot'] != null
              ? (json['device_in_plot'].toString().toLowerCase() == 'true')
              : null),
    );
  }
}

class TelemetryService {
  TelemetryService({required this.baseUrl}) {
    _startPruner();
  }

  final String baseUrl;

  // Map deviceId -> last telemetry
  final Map<String, TelemetryData> _latest = {};
  // active channels keyed by normalized (lowercase) device id
  final Map<String, WebSocketChannel> _channels = {};
  // desired subscriptions set (normalized ids) - used for reconnect logic
  final Set<String> _desiredSubscriptions = {};
  // simple reconnect attempt counters per device
  final Map<String, int> _reconnectAttempts = {};

  final _activeController = StreamController<List<TelemetryData>>.broadcast();
  Stream<List<TelemetryData>> get activeDevicesStream =>
      _activeController.stream;

  // Broadcast stream of all telemetry updates as they arrive. Consumers can
  // filter this stream for a particular device id to get live updates.
  final _updatesController = StreamController<TelemetryData>.broadcast();

  /// In-memory history of positions per device (normalized device id -> list
  /// of timestamped lat/lon entries). Kept in memory for the app lifetime.
  /// Each entry now also stores the PTO state and whether device was in-plot
  /// at the time so consumers can render point-level status.
  final Map<String, List<_LatLonEntry>> _positions = {};

  Timer? _pruneTimer;

  // Number of seconds to consider telemetry 'fresh' and therefore "online".
  // Increased from a small value to 120s so the UI shows online status
  // more leniently in presence of network/server skews.
  static const int _activeThresholdSeconds = 120;

  void _startPruner() {
    _pruneTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now().toUtc();
      final actives = <TelemetryData>[];
      _latest.forEach((k, v) {
        final diff = now.difference(v.timestamp.toUtc()).inSeconds;
        if (diff <= _activeThresholdSeconds) actives.add(v);
      });
      // Debug: print what the pruner considers active
      try {
        final keys = actives.map((a) => a.deviceId).toList();
        debugPrint('Telemetry.pruner: active keys -> $keys');
      } catch (_) {}
      // Determine which stored device ids are now considered offline and
      // clear their stored telemetry and position history to avoid showing
      // stale data in the UI.
      try {
        final activeIds = actives.map((a) => a.deviceId).toSet();
        final storedIds = _latest.keys.toList();
        for (final id in storedIds) {
          if (!activeIds.contains(id)) {
            // remove latest telemetry and positional history
            _latest.remove(id);
            _positions.remove(id);
            debugPrint(
                'Telemetry.pruner: cleared stored telemetry for offline id $id');
          }
        }
      } catch (_) {}

      _activeController.add(actives);
    });
  }

  /// Subscribe to telemetry websocket for [deviceId] (MAC address string).
  /// If already subscribed, this is a no-op.
  void subscribe(String deviceId) {
    final normKey = canonicalizeMac(deviceId);
    // record as desired subscription
    _desiredSubscriptions.add(normKey);
    // if already have a channel, nothing to do
    if (_channels.containsKey(normKey)) return;
    try {
      // Server expects the device id in the websocket URL to be uppercase
      // (case-sensitive). Internally we use a normalized lowercase key
      // (`normKey`) for maps, but construct the URL with the uppercase id.
      final url = '$baseUrl/ws/telemetry/${normKey.toUpperCase()}/';
      debugPrint(
          'Telemetry: attempting WebSocket connect to $url (norm=$normKey)');
      late final WebSocketChannel channel;
      try {
        debugPrint('Telemetry: connecting to $url via platform wrapper');
        channel = connectWebSocket(url);
      } catch (e) {
        debugPrint('Telemetry: websocket connect failed for $url: $e');
        rethrow;
      }
      // store channel under normalized key so unsubscribe works reliably
      _channels[normKey] = channel;
      // reset reconnect attempts on successful subscribe
      _reconnectAttempts[normKey] = 0;
      debugPrint('Telemetry: subscribed to $url (norm=$normKey)');
      channel.stream.listen((message) {
        try {
          // log raw message string for easier debugging
          try {
            debugPrint(
                'Telemetry raw (string) for $deviceId: ${safeStringify(message)}');
          } catch (_) {}
          Map<String, dynamic> data = (message is String)
              ? json.decode(message) as Map<String, dynamic>
              : (json.decode(utf8.decode(message)) as Map<String, dynamic>);
          try {
            debugPrint(
                'Telemetry raw message for $deviceId -> ${safeStringify(data)}');
          } catch (_) {}

          // Some servers send an envelope where the actual telemetry JSON is
          // contained as a string under `data` (or `payload`/`message`).
          // Unwrap that if present so TelemetryData.fromJson receives the
          // inner object that contains `device_id` and `timestamp`.
          try {
            Map<String, dynamic>? inner;
            if (data.containsKey('data')) {
              final d = data['data'];
              if (d is String) {
                try {
                  inner = json.decode(d) as Map<String, dynamic>;
                } catch (_) {
                  inner = null;
                }
              } else if (d is Map) {
                inner = Map<String, dynamic>.from(d);
              }
            }
            if (inner == null && data.containsKey('payload')) {
              final d = data['payload'];
              if (d is String) {
                try {
                  inner = json.decode(d) as Map<String, dynamic>;
                } catch (_) {
                  inner = null;
                }
              } else if (d is Map) {
                inner = Map<String, dynamic>.from(d);
              }
            }
            if (inner == null && data.containsKey('message')) {
              final d = data['message'];
              if (d is String) {
                try {
                  inner = json.decode(d) as Map<String, dynamic>;
                } catch (_) {
                  inner = null;
                }
              } else if (d is Map) {
                inner = Map<String, dynamic>.from(d);
              }
            }
            if (inner != null) {
              data = inner;
            }
          } catch (e) {
            debugPrint('Telemetry envelope unwrap error: $e');
          }

          TelemetryData t;
          try {
            t = TelemetryData.fromJson(data);
          } catch (e) {
            debugPrint('Telemetry: ignoring message (parse failed): $e');
            return;
          }
          final normId = canonicalizeMac(t.deviceId);
          // Detailed per-message debug: show subscription key, payload id, ts and age
          try {
            final now = DateTime.now().toUtc();
            final tsUtc = t.timestamp.toUtc();
            final ageSec = now.difference(tsUtc).inSeconds;
            debugPrint(
                'Telemetry.received on subscription=$normKey payload=$normId ts=${tsUtc.toIso8601String()} age=${ageSec}s');
          } catch (_) {}
          if (normId.isEmpty) return;
          final stored = TelemetryData(
            deviceId: normId,
            timestamp: t.timestamp.toUtc(),
            gpsSignalQuality: t.gpsSignalQuality,
            simSignalQuality: t.simSignalQuality,
            lat: t.lat,
            lon: t.lon,
            leftDistance: t.leftDistance,
            rightDistance: t.rightDistance,
            leftDensity: t.leftDensity,
            rightDensity: t.rightDensity,
            speed: t.speed,
            flowRate: t.flowRate,
            leftSolenoidState: t.leftSolenoidState,
            rightSolenoidState: t.rightSolenoidState,
            sprayMode: t.sprayMode,
            tankLevel: t.tankLevel,
            ptoState: t.ptoState,
            jobCompletionPercent: t.jobCompletionPercent,
            plot: t.plot,
            deviceInPlot: t.deviceInPlot,
          );
          // Store telemetry under the message's device id
          _latest[normId] = stored;
          // Persist lat/lon history for this device if present
          try {
            if (stored.lat != null && stored.lon != null) {
              final list =
                  _positions.putIfAbsent(normId, () => <_LatLonEntry>[]);
              list.add(_LatLonEntry(
                  timestamp: stored.timestamp.toUtc(),
                  lat: stored.lat!,
                  lon: stored.lon!,
                  ptoState: stored.ptoState,
                  deviceInPlot: stored.deviceInPlot));
            }
          } catch (_) {}
          // Also store telemetry under the subscription key (normKey) so that
          // channels which forward messages for other device_ids still mark
          // the subscribed control unit as active. Use the receive time for
          // the subscription entry so small network/server timestamp skews
          // don't mark the device offline immediately.
          try {
            if (normKey.isNotEmpty) {
              final receiveTs = DateTime.now().toUtc();
              _latest[normKey] = TelemetryData(
                deviceId: normKey,
                timestamp: receiveTs,
                gpsSignalQuality: stored.gpsSignalQuality,
                simSignalQuality: stored.simSignalQuality,
                lat: stored.lat,
                lon: stored.lon,
                leftDistance: stored.leftDistance,
                rightDistance: stored.rightDistance,
                leftDensity: stored.leftDensity,
                rightDensity: stored.rightDensity,
                speed: stored.speed,
                flowRate: stored.flowRate,
                leftSolenoidState: stored.leftSolenoidState,
                rightSolenoidState: stored.rightSolenoidState,
                sprayMode: stored.sprayMode,
                tankLevel: stored.tankLevel,
                ptoState: stored.ptoState,
                jobCompletionPercent: stored.jobCompletionPercent,
                plot: stored.plot,
                deviceInPlot: stored.deviceInPlot,
              );
              debugPrint(
                  'Telemetry: stored telemetry for payload=$normId and subscription=$normKey');
            }
          } catch (_) {}
          // publish live update for listeners and push current actives immediately
          try {
            _updatesController.add(stored);
          } catch (_) {}
          // push current actives immediately and log which ids are active
          final now = DateTime.now().toUtc();
          final actives = <TelemetryData>[];
          _latest.forEach((k, v) {
            final diff = now.difference(v.timestamp.toUtc()).inSeconds;
            if (diff <= _activeThresholdSeconds) actives.add(v);
          });
          try {
            final keys = actives.map((a) => a.deviceId).toList();
            debugPrint('Telemetry.immediate: active keys -> $keys');
          } catch (_) {}
          _activeController.add(actives);
        } catch (e) {
          debugPrint('Telemetry parse error: $e');
        }
      }, onError: (err) {
        debugPrint('Telemetry websocket error for $deviceId: $err');
      }, onDone: () {
        // remove channel and schedule reconnect if still desired
        _channels.remove(normKey);
        debugPrint('Telemetry websocket closed for $deviceId (norm=$normKey)');
        // reconnect with exponential backoff, but cap attempts
        final attempts = (_reconnectAttempts[normKey] ?? 0) + 1;
        _reconnectAttempts[normKey] = attempts;
        const maxAttempts = 5;
        if (_desiredSubscriptions.contains(normKey) &&
            attempts <= maxAttempts) {
          final delay = Duration(seconds: (1 << (attempts - 1)).clamp(1, 32));
          debugPrint(
              'Telemetry: scheduling reconnect for $normKey in ${delay.inSeconds}s (attempt $attempts)');
          Timer(delay, () {
            // only attempt if still desired and not currently connected
            if (_desiredSubscriptions.contains(normKey) &&
                !_channels.containsKey(normKey)) {
              subscribe(normKey);
            }
          });
        } else {
          if (!_desiredSubscriptions.contains(normKey)) {
            debugPrint(
                'Telemetry: not reconnecting $normKey (no longer desired)');
          } else {
            debugPrint(
                'Telemetry: max reconnect attempts reached for $normKey');
          }
        }
      });
    } catch (e) {
      debugPrint('Telemetry subscribe error for $deviceId: $e');
    }
  }

  void unsubscribe(String deviceId) {
    final norm = canonicalizeMac(deviceId);
    // mark as not desired
    _desiredSubscriptions.remove(norm);
    final ch = _channels.remove(norm);
    ch?.sink.close();
    _latest.remove(norm);
    _reconnectAttempts.remove(norm);
  }

  /// Subscribe to a set of device IDs and ensure only those are kept subscribed.
  /// Normalizes IDs (trim+lower) and will unsubscribe any channels not in [deviceIds].
  void subscribeToDevices(List<String> deviceIds) {
    debugPrint('Telemetry.subscribeToDevices called with: $deviceIds');
    final normIds = deviceIds
        .map((d) => canonicalizeMac(d))
        .where((d) => d.isNotEmpty)
        .toSet();
    // update desired subscriptions
    _desiredSubscriptions
      ..clear()
      ..addAll(normIds);
    debugPrint('Telemetry.subscribeToDevices normalized to: $normIds');
    // subscribe missing
    for (final id in normIds) {
      if (!_channels.containsKey(id)) {
        subscribe(id);
      }
    }
    // unsubscribe extras
    final toRemove = _channels.keys.where((k) => !normIds.contains(k)).toList();
    for (final k in toRemove) {
      unsubscribe(k);
    }
  }

  /// Get a list of currently active device telemetry (timestamp within 3s)
  List<TelemetryData> getActiveDevices() {
    final now = DateTime.now().toUtc();
    return _latest.values
        .where((v) =>
            now.difference(v.timestamp.toUtc()).inSeconds <=
            _activeThresholdSeconds)
        .toList();
  }

  /// Debug: list of currently subscribed (normalized) device ids
  List<String> get subscribedDeviceIds => _channels.keys.toList();

  /// Debug: snapshot of latest telemetry map (deviceId -> TelemetryData)
  Map<String, TelemetryData> get latestTelemetry =>
      Map<String, TelemetryData>.from(_latest);

  /// Return a copy of the stored positions (lat/lon history) for [deviceId].
  List<Map<String, dynamic>> getPositions(String deviceId) {
    final norm = canonicalizeMac(deviceId);
    final list = _positions[norm] ?? <_LatLonEntry>[];
    return list
        .map((e) => <String, dynamic>{
              'timestamp': e.timestamp.toIso8601String(),
              'lat': e.lat,
              'lon': e.lon,
              'pto': e.ptoState,
              'device_in_plot': e.deviceInPlot,
            })
        .toList();
  }

  /// Stream of live TelemetryData updates for a particular device id.
  Stream<TelemetryData> deviceTelemetryStream(String deviceId) {
    final norm = canonicalizeMac(deviceId);
    return _updatesController.stream
        .where((t) => canonicalizeMac(t.deviceId) == norm);
  }

  void dispose() {
    for (final ch in _channels.values) {
      ch.sink.close();
    }
    _channels.clear();
    _latest.clear();
    _pruneTimer?.cancel();
    _positions.clear();
    try {
      _updatesController.close();
    } catch (_) {}
    try {
      _activeController.close();
    } catch (_) {}
  }
}

/// Small internal type for storing timestamped lat/lon history.
class _LatLonEntry {
  final DateTime timestamp;
  final double lat;
  final double lon;
  final int? ptoState;
  final bool? deviceInPlot;
  _LatLonEntry({
    required this.timestamp,
    required this.lat,
    required this.lon,
    this.ptoState,
    this.deviceInPlot,
  });
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  // Use provided base URL; default to ws://13.201.0.34:8001
  final svc = TelemetryService(baseUrl: 'ws://13.201.0.34:8001');
  ref.onDispose(() => svc.dispose());
  return svc;
});

final activeDevicesProvider = StreamProvider<List<TelemetryData>>((ref) {
  final svc = ref.watch(telemetryServiceProvider);
  return svc.activeDevicesStream;
});
