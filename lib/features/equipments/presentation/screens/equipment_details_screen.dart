import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/features/auth/presentation/providers/users_providers.dart';
import '../../domain/entities/equipment.dart';
import '../providers/equipment_providers.dart';
import 'package:simdaas/features/plot_mapping/presentation/providers/plot_providers.dart';
import 'create_equipment_screen.dart';
import 'create_control_unit_screen.dart';
import 'create_sprayer_screen.dart';
import 'create_tractor_screen.dart';

class EquipmentDetailsScreen extends ConsumerStatefulWidget {
  final EquipmentEntity equipment;
  final bool readOnly;
  const EquipmentDetailsScreen(
      {super.key, required this.equipment, this.readOnly = false});

  @override
  ConsumerState<EquipmentDetailsScreen> createState() =>
      _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState
    extends ConsumerState<EquipmentDetailsScreen> {
  late EquipmentEntity displayedEquipment;

  String _ownerDisplay(String? userField) {
    if (userField == null) return '-';
    final raw = userField.trim();

    // Try strict JSON decode if the string contains a JSON-like object
    if (raw.contains('{') && raw.contains('}')) {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < end) {
        final body = raw.substring(start, end + 1);
        try {
          final m = json.decode(body) as Map<String, dynamic>;
          final val = m['username'] ?? m['name'] ?? m['user'] ?? m['id'];
          if (val != null) return val.toString();
        } catch (_) {
          // ignore and fall back to relaxed parsing
        }
      }
    }

    // Relaxed extraction: look for username: value or username = value patterns
    final unameRe = RegExp("username\\s*[:=]\\s*['\\\"]?([A-Za-z0-9_.@\\-]+)",
        caseSensitive: false);
    final unameMatch = unameRe.firstMatch(raw);
    if (unameMatch != null) return unameMatch.group(1)!.trim();

    // fallback: try name, user, then id
    final altRe = RegExp(
        "(?:name|user)\\s*[:=]\\s*['\\\"]?([A-Za-z0-9_.@\\-]+)",
        caseSensitive: false);
    final altMatch = altRe.firstMatch(raw);
    if (altMatch != null) return altMatch.group(1)!.trim();

    final idRe =
        RegExp("\\bid\\s*[:=]\\s*([0-9A-Za-z_\\-]+)", caseSensitive: false);
    final idMatch = idRe.firstMatch(raw);
    if (idMatch != null) return idMatch.group(1)!.trim();

    // final fallback: more permissive capture until comma or closing brace
    final looseRe =
        RegExp(r"username\s*[:=]\s*([^,}\n]+)", caseSensitive: false);
    final looseMatch = looseRe.firstMatch(raw);
    if (looseMatch != null) {
      var v = looseMatch.group(1)!.trim();
      // strip wrapping quotes if present
      if ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'"))) {
        v = v.substring(1, v.length - 1);
      }
      return v;
    }

    // nothing found — return the raw string so UI shows something instead of crashing
    return raw;
  }

  // Resolve equipment name (sprayer/tractor/control unit) from a provider list
  String _resolveEquipmentName(
      String? id, AsyncValue<List<EquipmentEntity>> listAsync) {
    if (id == null) return '-';
    return listAsync.maybeWhen(
        data: (items) {
          final found = items.where((e) => e.id == id).toList();
          if (found.isNotEmpty) return found.first.name;
          return _extractNameFromLinked(id, {
                for (var e in items) e.id: e.name,
              }) ??
              id;
        },
        orElse: () =>
            _extractNameFromLinked(id ?? '', {
              for (var e in listAsync.value ?? []) e.id: e.name,
            }) ??
            (id));
  }

  String? _extractNameFromLinked(String linked, Map<String, String> plotMap) {
    if (linked.isEmpty) return null;

    // Direct lookup first (covers plain id strings)
    final direct = plotMap[linked];
    if (direct != null) return direct;

    // If it looks like an object (starts with '{'), try to parse it.
    if (linked.trim().startsWith('{')) {
      try {
        // Normalize single quotes to double quotes
        var s = linked.replaceAll("'", '"');
        // Quote unquoted keys: {key: -> {"key":
        s = s.replaceAllMapped(RegExp(r'([\{,\s])(\w+)\s*:'), (m) {
          final lead = m.group(1) ?? '';
          final key = m.group(2) ?? '';
          return '$lead"$key":';
        });
        final decoded = json.decode(s);
        if (decoded is Map && decoded.containsKey('name')) {
          return decoded['name']?.toString();
        }
        if (decoded is Map && decoded.containsKey('id')) {
          final id = decoded['id']?.toString();
          if (id != null && id.isNotEmpty) return plotMap[id];
        }
      } catch (_) {
        // ignore parse errors
      }
    }

    // As a last attempt, try to find an id-like number inside the string
    final idMatch = RegExp(r"id\s*[:=]\s*([0-9A-Za-z-]+)").firstMatch(linked);
    if (idMatch != null) {
      final id = idMatch.group(1);
      if (id != null && id.isNotEmpty) return plotMap[id];
    }

    return null;
  }

  // Resolve plot name from plots provider
  String _resolvePlotName(String? id, AsyncValue<List<dynamic>> plotsAsync) {
    if (id == null) return '-';
    return plotsAsync.maybeWhen(
        data: (items) {
          try {
            final found = items.where((p) => p.id == id).toList();
            if (found.isNotEmpty) return found.first.name;
          } catch (_) {}
          return _extractNameFromLinked(id, {
                for (var e in items) e.id: e.name,
              }) ??
              id;
        },
        orElse: () =>
            _extractNameFromLinked(id ?? '', {
              for (var e in plotsAsync.value ?? []) e.id: e.name,
            }) ??
            (id));
  }

  @override
  void initState() {
    super.initState();
    displayedEquipment = widget.equipment;
  }

  @override
  Widget build(BuildContext context) {
    // Determine which user id to use when fetching lists. Prefer the
    // authenticated user's id so providers are keyed consistently.
    final currentUserId = ref.read(authServiceProvider).currentUserId ??
        widget.equipment.userId ??
        'demo_user';
    final status = (displayedEquipment.status ?? 'vacant').toUpperCase();
    // watch other equipment/plot lists so we can display names instead of ids
    final sprayersAsync = ref.watch(sprayersProvider(currentUserId));
    final tractorsAsync = ref.watch(tractorsProvider(currentUserId));
    final plotsAsync = ref.watch(plotsListProvider(currentUserId));
    return Scaffold(
      appBar: AppBar(
        title: Text(displayedEquipment.name),
        actions: widget.readOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    // pass the equipment as a raw map to the create/edit screen
                    final existing = {
                      'id': displayedEquipment.id,
                      'category': displayedEquipment.category,
                      'name': displayedEquipment.name,
                      'userId': displayedEquipment.userId,
                      'status': displayedEquipment.status,
                      'controlUnitId': displayedEquipment.controlUnitId,
                      'mountingHeight': displayedEquipment.mountingHeight,
                      'lidarNozzleDistance':
                          displayedEquipment.lidarNozzleDistance,
                      'ultrasonicDistance':
                          displayedEquipment.ultrasonicDistance,
                      'wheelDiameter': displayedEquipment.wheelDiameter,
                      'screwsInWheel': displayedEquipment.screwsInWheel,
                      'nozzleCount': displayedEquipment.nozzleCount,
                      'tankCapacity': displayedEquipment.tankCapacity,
                      'axleLength': displayedEquipment.axleLength,
                      'hingeToAxle': displayedEquipment.hingeToAxle,
                      'hingeToNozzle': displayedEquipment.hingeToNozzle,
                      'hingeToControlUnit':
                          displayedEquipment.hingeToControlUnit,
                      'macAddress': displayedEquipment.macAddress,
                      'linkedSprayerId': displayedEquipment.linkedSprayerId,
                      'linkedTractorId': displayedEquipment.linkedTractorId,
                      'linkedPlotId': displayedEquipment.linkedPlotId,
                    };
                    // Route to the appropriate editor. Use the specialized
                    // control unit editor so the control unit identifier is
                    // treated as non-editable when editing an existing unit.
                    // Route to the appropriate editor. Capture the result so
                    // we only invalidate providers when the editor signals
                    // a successful change (it pops `true`).
                    final cat = displayedEquipment.category.toLowerCase();
                    final result = cat == 'control_unit'
                        ? await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CreateControlUnitScreen(
                                existingData: existing)))
                        : cat == 'sprayer'
                            ? await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => CreateSprayerScreen(
                                        existingData: existing)))
                            : cat == 'tractor'
                                ? await Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => CreateTractorScreen(
                                            existingData: existing)))
                                : await Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => CreateEquipmentScreen(
                                            existingData: existing)));

                    if (result == true) {
                      ref.invalidate(equipmentsListProvider(currentUserId));
                      switch (displayedEquipment.category.toLowerCase()) {
                        case 'control_unit':
                          ref.invalidate(controlUnitsProvider(currentUserId));
                          break;
                        case 'sprayer':
                          ref.invalidate(sprayersProvider(currentUserId));
                          break;
                        case 'tractor':
                          ref.invalidate(tractorsProvider(currentUserId));
                          break;
                        default:
                          break;
                      }

                      try {
                        final repo = ref.read(equipmentRepoProvider);
                        final fresh = await repo.getEquipments(currentUserId);
                        final found = fresh.firstWhere(
                            (e) => e.id == displayedEquipment.id,
                            orElse: () => displayedEquipment);
                        setState(() => displayedEquipment = found);
                      } catch (_) {
                        // ignore fetch errors; provider invalidation will
                        // eventually update the UI
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: const Text('Delete equipment'),
                              content:
                                  Text('Delete ${displayedEquipment.name}?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Delete')),
                              ],
                            ));
                    if (ok == true) {
                      final ctrl = ref.read(equipmentControllerProvider);
                      try {
                        await ctrl.delete(displayedEquipment.id,
                            category: displayedEquipment.category);
                        // Use the signed-in user's id when invalidating providers
                        // because list providers are keyed by the current user.
                        ref.invalidate(equipmentsListProvider(currentUserId));
                        switch (displayedEquipment.category.toLowerCase()) {
                          case 'control_unit':
                            ref.invalidate(controlUnitsProvider(currentUserId));
                            break;
                          case 'sprayer':
                            ref.invalidate(sprayersProvider(currentUserId));
                            break;
                          case 'tractor':
                            ref.invalidate(tractorsProvider(currentUserId));
                            break;
                          default:
                            break;
                        }

                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Equipment deleted')));
                      } catch (err) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Delete failed')));
                      }
                    }
                  },
                )
              ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // left: flexible area for name/category/details so long text wraps
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayedEquipment.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(displayedEquipment.category, softWrap: true),
                  ]),
            ),

            const SizedBox(width: 12),
            // right: status chip
            Chip(
              label: Text(status, style: const TextStyle(color: Colors.white)),
              backgroundColor: status == 'VACANT' ? Colors.green : Colors.red,
            )
          ]),
          const SizedBox(height: 16),
          // allow owner and other fields to wrap and flow vertically
          if (displayedEquipment.userId == null)
            const Text('Owner: -', softWrap: true)
          else
            ref.watch(userByIdProvider(displayedEquipment.userId!)).when(
                data: (u) {
                  final ownerName = u != null
                      ? (u['username'] ??
                              u['name'] ??
                              u['email'] ??
                              displayedEquipment.userId)
                          .toString()
                      : _ownerDisplay(displayedEquipment.userId);
                  return Text('Owner: $ownerName', softWrap: true);
                },
                loading: () => const Text('Owner: ...', softWrap: true),
                error: (_, __) => Text(
                    'Owner: ${_ownerDisplay(displayedEquipment.userId)}',
                    softWrap: true)),
          if (displayedEquipment.createdAt != null)
            Text(
                'Created: ${displayedEquipment.createdAt!.toLocal().toIso8601String()}',
                softWrap: true),
          if (displayedEquipment.updatedAt != null)
            Text(
                'Updated: ${displayedEquipment.updatedAt!.toLocal().toIso8601String()}',
                softWrap: true),
          const SizedBox(height: 8),
          if (displayedEquipment.category == 'sprayer') ...[
            Text(
                'Wheel diameter (m): ${displayedEquipment.wheelDiameter ?? '-'}',
                softWrap: true),
            Text(
                'No. of screws in wheel: ${displayedEquipment.screwsInWheel ?? '-'}',
                softWrap: true),
            Text('Axle length (m): ${displayedEquipment.axleLength ?? '-'}',
                softWrap: true),
            // nozzle count and tank capacity were not shown previously; show them
            Text('Number of nozzles: ${displayedEquipment.nozzleCount ?? '-'}',
                softWrap: true),
            Text('Tank capacity (L): ${displayedEquipment.tankCapacity ?? '-'}',
                softWrap: true),
            Text('Hinge → Axle (m): ${displayedEquipment.hingeToAxle ?? '-'}',
                softWrap: true),
            Text(
                'Hinge → Nozzle (m): ${displayedEquipment.hingeToNozzle ?? '-'}',
                softWrap: true),
            Text(
                'Hinge → Control unit (m): ${displayedEquipment.hingeToControlUnit ?? '-'}',
                softWrap: true),
            const SizedBox(height: 8),
          ] else if (displayedEquipment.category == 'tractor') ...[
            Text(
                'Wheel diameter (m): ${displayedEquipment.wheelDiameter ?? '-'}',
                softWrap: true),
            Text('Screws in wheel: ${displayedEquipment.screwsInWheel ?? '-'}',
                softWrap: true),
            Text('Axle length (m): ${displayedEquipment.axleLength ?? '-'}',
                softWrap: true),
            const SizedBox(height: 8),
          ],
          if (displayedEquipment.category == 'control_unit') ...[
            Text('MAC address: ${displayedEquipment.macAddress ?? '-'}',
                softWrap: true),
            Text(
                'Linked sprayer: ${_resolveEquipmentName(displayedEquipment.linkedSprayerId, sprayersAsync)}',
                softWrap: true),
            Text(
                'Linked tractor: ${_resolveEquipmentName(displayedEquipment.linkedTractorId, tractorsAsync)}',
                softWrap: true),
            Text(
                'Linked plot: ${_resolvePlotName(displayedEquipment.linkedPlotId, plotsAsync)}',
                softWrap: true),
            Text(
                'Distance sensor→nozzle (m): ${displayedEquipment.lidarNozzleDistance ?? '-'}',
                softWrap: true),
            Text(
                'Mounting height of lidar (m): ${displayedEquipment.mountingHeight ?? '-'}',
                softWrap: true),
            Text(
                'Ultrasonic distance (m): ${displayedEquipment.ultrasonicDistance ?? '-'}',
                softWrap: true),
            const SizedBox(height: 8),
          ],
        ]),
      ),
    );
  }
}
