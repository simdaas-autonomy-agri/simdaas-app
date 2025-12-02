import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signal_strength_indicator/signal_strength_indicator.dart';
import 'package:simdaas/core/utils/error_utils.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;
import '../providers/monitoring_providers.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/core/services/telemetry_service.dart';
import 'package:simdaas/core/utils/mac_utils.dart';
import 'dart:async';

class MonitoringScreen extends ConsumerStatefulWidget {
  final String? plotId;
  final String? jobId;
  final String? deviceId;
  const MonitoringScreen({super.key, this.plotId, this.jobId, this.deviceId});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  List<Map<String, dynamic>> positions = [];
  TelemetryData? latestTelemetry;
  StreamSubscription<TelemetryData>? _deviceSub;
  final MapController _mapController = MapController();
  bool _outOfPlotSnackVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.deviceId != null && widget.deviceId!.isNotEmpty) {
      final svc = ref.read(telemetryServiceProvider);
      final normId = canonicalizeMac(widget.deviceId!);
      // Ensure service is subscribed (no-op if already subscribed).
      try {
        svc.subscribe(normId);
      } catch (_) {}

      // Seed positions and latest telemetry from the service snapshot if available.
      try {
        positions = svc.getPositions(normId);
      } catch (_) {
        positions = [];
      }
      try {
        latestTelemetry = svc.latestTelemetry[normId];
      } catch (_) {
        latestTelemetry = null;
      }

      // If initial seeded telemetry indicates device is out of plot, show
      // the persistent notification after the first frame so Scaffold is
      // available.
      if (latestTelemetry != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateOutOfPlotSnack(latestTelemetry);
        });
      }

      try {
        _deviceSub = svc.deviceTelemetryStream(normId).listen((t) {
          setState(() {
            latestTelemetry = t;
            if (t.lat != null && t.lon != null) {
              positions.add(<String, dynamic>{
                'timestamp': t.timestamp.toIso8601String(),
                'lat': t.lat,
                'lon': t.lon,
                'pto': t.ptoState,
                'device_in_plot': t.deviceInPlot,
              });
            }
          });
          // Show or hide persistent out-of-plot snackbar based on payload.
          _updateOutOfPlotSnack(t);
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    // Hide any visible snack before leaving the screen.
    try {
      if (_outOfPlotSnackVisible)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (_) {}
    _deviceSub?.cancel();
    super.dispose();
  }

  int getSignalBars(int signalQuality) {
    if (signalQuality > -73)
      return 5;
    else if (signalQuality > -83 && signalQuality <= -73)
      return 4;
    else if (signalQuality > -93 && signalQuality <= -83)
      return 3;
    else if (signalQuality > -103 && signalQuality <= -93)
      return 2;
    else if (signalQuality > -113 && signalQuality <= -103)
      return 1;
    else
      return 0;
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    final plotsAsync = ref.watch(fm_providers.plotsListProvider(userId));
    final metricsAsync = ref.watch(monitoringStreamProvider(userId));

    Widget signalChip(IconData icon, String label, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12))
          ]),
        );

    return Scaffold(
      appBar: AppBar(
          title: Row(children: [
        Text('Data Monitoring'),
        const Spacer(),
        if (latestTelemetry != null) ...[
          // GPS quality
          Builder(builder: (ctx) {
            final g = latestTelemetry!.gpsSignalQuality;
            Color col = Colors.grey;
            String lbl = '-';
            if (g != null) {
              lbl = g.toString();
              col =
                  g >= 3 ? Colors.white : (g >= 1 ? Colors.orange : Colors.red);
            }
            return signalChip(Icons.gps_fixed, lbl, col);
          }),
          const SizedBox(width: 15),
          SignalStrengthIndicator.bars(
            value: latestTelemetry!.simSignalQuality != null
                ? getSignalBars(latestTelemetry!.simSignalQuality!) / 5
                : 0,
            size: 20,
            barCount: 5,
            spacing: 0.5,
            activeColor: Colors.white,
            inactiveColor: Colors.blueGrey,
          )

          // // SIM signal (RSSI style)
          // Builder(builder: (ctx) {
          //   final s = latestTelemetry!.simSignalQuality;
          //   Color col = Colors.grey;
          //   String lbl = '-';
          //   if (s != null) {
          //     lbl = s.toString();
          //     if (s >= -70)
          //       col = Colors.white;
          //     else if (s >= -90)
          //       col = Colors.orange;
          //     else
          //       col = Colors.red;
          //   }
          //   return signalChip(Icons.signal_cellular_alt, lbl, col);
          // }),
        ]
      ])),
      body: plotsAsync.when(
        data: (plots) {
          if (plots.isEmpty)
            return const Center(child: Text('No plots available'));
          final plot = widget.plotId != null
              ? plots.cast<fm_models.PlotModel>().firstWhere(
                  (f) => f.id == widget.plotId,
                  orElse: () => plots.cast<fm_models.PlotModel>().first)
              : plots.cast<fm_models.PlotModel>().first;
          // final center = positions.isNotEmpty
          //     ? LatLng((positions.last['lat'] as num).toDouble(),
          //         (positions.last['lon'] as num).toDouble())
          //     : plot.polygon.first;
          final center = plot.polygon.isNotEmpty
              ? plot.polygon.first
              : LatLng((positions.last['lat'] as num).toDouble(),
                  (positions.last['lon'] as num).toDouble());
          return Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 18.0),
              children: [
                TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                    subdomains: const ['a', 'b', 'c']),
                if (plot.polygon.isNotEmpty)
                  PolygonLayer(polygons: [
                    Polygon(
                        points: plot.polygon,
                        color: Colors.green.withOpacity(0.15),
                        borderColor: Colors.green,
                        borderStrokeWidth: 2.0)
                  ]),
                // If a device id was provided, render historical positions and live marker
                if (widget.deviceId != null && positions.isNotEmpty) ...[
                  // Build colored polyline segments by grouping consecutive
                  // position points that share the same color according to the
                  // device_in_plot and pto state.
                  PolylineLayer(
                      polylines:
                          _buildColoredPolylinesFromPositions(positions)),
                ],
                if (widget.deviceId != null && latestTelemetry != null)
                  MarkerLayer(markers: [
                    Marker(
                        point: LatLng(latestTelemetry!.lat ?? 0.0,
                            latestTelemetry!.lon ?? 0.0),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on,
                            color: _markerColorForTelemetry(latestTelemetry!))),
                  ])
              ],
            ),
            // Overlay: Top card (nozzles + ultrasonics) and bottom controls
            Positioned.fill(
              child: metricsAsync.when(
                data: (metrics) {
                  final m = metrics[plot.id] ?? <String, dynamic>{};

                  String read(dynamic v) => v == null ? '-' : v.toString();

                  // Prefer live telemetry values when available, otherwise fall back
                  // to the metrics provider values.
                  final t = latestTelemetry;
                  final leftNozzle = t != null && t.leftSolenoidState != null
                      ? t.leftSolenoidState.toString()
                      : "-";
                  final rightNozzle = t != null && t.rightSolenoidState != null
                      ? t.rightSolenoidState.toString()
                      : "-";
                  final leftUltra = t != null && t.leftDistance != null
                      ? t.leftDistance!.toStringAsFixed(2)
                      : read(m['leftUltrasonic'] ?? m['ultraLeft']);
                  final rightUltra = t != null && t.rightDistance != null
                      ? t.rightDistance!.toStringAsFixed(2)
                      : read(m['rightUltrasonic'] ?? m['ultraRight']);
                  final coverage = t != null && t.jobCompletionPercent != null
                      ? t.jobCompletionPercent!
                      : (m['coveragePercent'] ?? m['coverage'] ?? 0).toDouble();

                  // final leftNozzle = t != null && t.leftSolenoidState != null
                  //     ? (t.leftSolenoidState == 1 ? 'On' : 'Off')
                  //     : read(m['leftNozzle'] ?? m['nozzleLeft']);
                  // final rightNozzle = t != null && t.rightSolenoidState != null
                  //     ? (t.rightSolenoidState == 1 ? 'On' : 'Off')
                  //     : read(m['rightNozzle'] ?? m['nozzleRight']);
                  // final leftUltra = t != null && t.leftDistance != null
                  //     ? t.leftDistance!.toStringAsFixed(2)
                  //     : read(m['leftUltrasonic'] ?? m['ultraLeft']);
                  // final rightUltra = t != null && t.rightDistance != null
                  //     ? t.rightDistance!.toStringAsFixed(2)
                  //     : read(m['rightUltrasonic'] ?? m['ultraRight']);
                  // final coverage =
                  //     (m['coveragePercent'] ?? m['coverage'] ?? 0).toDouble();
                  final flowRate = t != null && t.flowRate != null
                      ? t.flowRate!.toStringAsFixed(2)
                      : read(m['flowRate']);
                  final speed = t != null && t.speed != null
                      ? t.speed!.toStringAsFixed(2)
                      : read(m['tractorSpeed'] ?? m['speed']);
                  final tank = t != null && t.tankLevel != null
                      ? t.tankLevel!.toStringAsFixed(2)
                      : read(m['tankLevel']);
                  final ptoOn = t != null && t.ptoState != null
                      ? (t.ptoState == 1)
                      : ((m['ptoState'] ?? m['pto'] ?? false) == true);
                  final autoOn = t != null && t.sprayMode != null
                      ? (t.sprayMode == 1)
                      : ((m['autoMode'] ?? m['auto'] ?? false) == true);

                  return Stack(children: [
                    // Top overlay
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: SafeArea(
                        child: Card(
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Row 1: Left nozzle | Right nozzle
                                  Row(children: [
                                    Expanded(
                                        child: _metricBlock(
                                            'Left nozzle', leftNozzle)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _metricBlock(
                                            'Right nozzle', rightNozzle)),
                                  ]),
                                  const SizedBox(height: 8),
                                  // Row 2: Left sensor | Right sensor
                                  Row(children: [
                                    Expanded(
                                        child: _metricBlock(
                                            'Left sensor', leftUltra)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _metricBlock(
                                            'Right sensor', rightUltra)),
                                  ]),
                                ]),
                          ),
                        ),
                      ),
                    ),

                    // Bottom overlay: progress, summary row, PTO
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: SafeArea(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Card(
                            color: Colors.white.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Progress bar row
                                    Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            const Text('Coverage',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54)),
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                                value: (coverage.clamp(0, 100) /
                                                    100.0)),
                                            const SizedBox(height: 6),
                                            Text(
                                                '${coverage.toStringAsFixed(1)}% covered',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ])),
                                    ]),
                                    const SizedBox(height: 12),

                                    // summary single-line row
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _smallStat('Flow', flowRate),
                                          _smallStat('Speed', speed),
                                          _smallStat('Tank', tank),
                                        ]),
                                    const SizedBox(height: 12),

                                    // PTO toggle row
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text('PTO',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 12),
                                          StatefulBuilder(
                                              builder: (ctx, setStateInner) {
                                            var value = ptoOn;
                                            return Switch(
                                              value: value,
                                              onChanged: (v) {
                                                // locally toggle; provider hook may be added later
                                                setStateInner(() => value = v);
                                              },
                                            );
                                          }),
                                          const Text('Auto', // spray mode
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 12),
                                          StatefulBuilder(
                                              builder: (ctx, setStateInner) {
                                            var value = autoOn;
                                            return Switch(
                                              value: value,
                                              onChanged: (v) {
                                                // locally toggle; provider hook may be added later
                                                setStateInner(() => value = v);
                                              },
                                            );
                                          })
                                        ])
                                  ]),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]);
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => Positioned(
                    left: 12,
                    top: 12,
                    child: Card(
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(extractErrorMessage(e))))),
              ),
            )
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(extractErrorMessage(e))),
      ),
      floatingActionButton: widget.deviceId != null
          ? FloatingActionButton(
              heroTag: 'center_current',
              mini: true,
              onPressed: _goToCurrentPosition,
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }

  Color _markerColorForTelemetry(TelemetryData t) {
    try {
      final inPlot = t.deviceInPlot == true ||
          (t.deviceInPlot?.toString().toLowerCase() == 'true');
      final ptoOn = (t.ptoState != null && t.ptoState == 1);
      if (inPlot && ptoOn) return Colors.blue;
      if (inPlot && !ptoOn) return Colors.orange;
    } catch (_) {}
    return Colors.red;
  }

  void _goToCurrentPosition() {
    try {
      LatLng? target;
      if (latestTelemetry != null &&
          latestTelemetry!.lat != null &&
          latestTelemetry!.lon != null) {
        target = LatLng(latestTelemetry!.lat!, latestTelemetry!.lon!);
      } else if (positions.isNotEmpty) {
        final last = positions.last;
        target = LatLng(
            (last['lat'] as num).toDouble(), (last['lon'] as num).toDouble());
      }
      if (target != null) {
        // Keep zoom at current controller zoom if available; otherwise use 18.0
        double zoom = 18.0;
        try {
          // Try to read zoom from MapController.camera when available.
          final cam = _mapController.camera;
          zoom = cam.zoom;
        } catch (_) {}
        _mapController.move(target, zoom);
      }
    } catch (_) {}
  }

  // Show a persistent SnackBar when telemetry reports the device is
  // outside the plot. The SnackBar is hidden once the device reports
  // in-plot again. This function is safe to call from listeners.
  void _updateOutOfPlotSnack(TelemetryData? t) {
    if (!mounted) return;
    try {
      final isInPlot = t != null &&
          (t.deviceInPlot == true ||
              (t.deviceInPlot?.toString().toLowerCase() == 'true'));
      if (!isInPlot) {
        if (!_outOfPlotSnackVisible) {
          _outOfPlotSnackVisible = true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Device is outside the assigned plot'),
            duration: const Duration(days: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
            action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  try {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  } catch (_) {}
                  _outOfPlotSnackVisible = false;
                }),
          ));
        }
      } else {
        if (_outOfPlotSnackVisible) {
          try {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          } catch (_) {}
          _outOfPlotSnackVisible = false;
        }
      }
    } catch (_) {}
  }

  // Compute the color for a single stored position entry.
  Color _colorForPositionEntry(Map<String, dynamic> p) {
    try {
      final pto = p['pto'];
      final deviceInPlot = p['device_in_plot'];
      final ptoOn =
          (pto != null && (pto is int ? pto == 1 : pto.toString() == '1'));
      final inPlotBool = (deviceInPlot == true ||
          (deviceInPlot != null &&
              deviceInPlot.toString().toLowerCase() == 'true'));
      if (inPlotBool && ptoOn) return Colors.blue;
      if (inPlotBool && !ptoOn) return Colors.orange;
    } catch (_) {}
    return Colors.red;
  }

  // Build a list of Polylines by grouping consecutive position points that
  // share the same color. Each resulting Polyline will be drawn with the
  // color for that segment.
  List<Polyline> _buildColoredPolylinesFromPositions(
      List<Map<String, dynamic>> pos) {
    final List<Polyline> result = [];
    if (pos.length < 2) return result;

    List<LatLng> currentPoints = [];
    Color? currentColor;

    for (var i = 0; i < pos.length; i++) {
      final p = pos[i];
      final lat = (p['lat'] as num).toDouble();
      final lon = (p['lon'] as num).toDouble();
      final color = _colorForPositionEntry(p);

      if (currentColor == null) {
        // start new segment
        currentColor = color;
        currentPoints = [LatLng(lat, lon)];
      } else if (color == currentColor) {
        currentPoints.add(LatLng(lat, lon));
      } else {
        // flush previous segment if it has at least two points
        if (currentPoints.length >= 2) {
          result.add(Polyline(
              points: List<LatLng>.from(currentPoints),
              strokeWidth: 4.0,
              color: currentColor));
        }
        // start new segment
        currentColor = color;
        currentPoints = [LatLng(lat, lon)];
      }
    }

    // flush last segment
    if (currentPoints.length >= 2 && currentColor != null) {
      result.add(Polyline(
          points: List<LatLng>.from(currentPoints),
          strokeWidth: 4.0,
          color: currentColor));
    }

    return result;
  }
}

Widget _metricBlock(String title, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 6),
      Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]),
  );
}

Widget _smallStat(String label, String value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
