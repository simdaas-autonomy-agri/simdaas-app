import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../../domain/entities/equipment.dart';
import '../providers/equipment_providers.dart';
import 'create_equipment_screen.dart';
import 'create_control_unit_screen.dart';

class EquipmentDetailsScreen extends ConsumerWidget {
  final EquipmentEntity equipment;
  final bool readOnly;
  const EquipmentDetailsScreen(
      {super.key, required this.equipment, this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = (equipment.status ?? 'vacant').toUpperCase();
    final userId = equipment.userId;
    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.name),
        actions: readOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    // pass the equipment as a raw map to the create/edit screen
                    final existing = {
                      'id': equipment.id,
                      'category': equipment.category,
                      'name': equipment.name,
                      'userId': equipment.userId,
                      'status': equipment.status,
                      'controlUnitId': equipment.controlUnitId,
                      'mountingHeight': equipment.mountingHeight,
                      'lidarNozzleDistance': equipment.lidarNozzleDistance,
                      'ultrasonicDistance': equipment.ultrasonicDistance,
                      'wheelDiameter': equipment.wheelDiameter,
                      'screwsInWheel': equipment.screwsInWheel,
                      'axleLength': equipment.axleLength,
                      'hingeToAxle': equipment.hingeToAxle,
                      'hingeToNozzle': equipment.hingeToNozzle,
                      'hingeToControlUnit': equipment.hingeToControlUnit,
                      'macAddress': equipment.macAddress,
                      'linkedSprayerId': equipment.linkedSprayerId,
                      'linkedTractorId': equipment.linkedTractorId,
                    };
                    // Route to the appropriate editor. Use the specialized
                    // control unit editor so the control unit identifier is
                    // treated as non-editable when editing an existing unit.
                    if (equipment.category.toLowerCase() == 'control_unit') {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              CreateControlUnitScreen(existingData: existing)));
                    } else {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              CreateEquipmentScreen(existingData: existing)));
                    }
                    if (userId != null)
                      ref.invalidate(equipmentsListProvider(userId));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                              title: const Text('Delete equipment'),
                              content: Text('Delete ${equipment.name}?'),
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
                        await ctrl.delete(equipment.id,
                            category: equipment.category);
                        // Use the signed-in user's id when invalidating providers
                        // because list providers are keyed by the current user.
                        final currentUserId =
                            ref.read(authServiceProvider).currentUserId ??
                                userId ??
                                'demo_user';
                        ref.invalidate(equipmentsListProvider(currentUserId));
                        switch (equipment.category.toLowerCase()) {
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
                    Text(equipment.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(equipment.category, softWrap: true),
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
          Text('Owner: ${equipment.userId ?? '-'}', softWrap: true),
          if (equipment.createdAt != null)
            Text('Created: ${equipment.createdAt!.toLocal().toIso8601String()}',
                softWrap: true),
          if (equipment.updatedAt != null)
            Text('Updated: ${equipment.updatedAt!.toLocal().toIso8601String()}',
                softWrap: true),
          const SizedBox(height: 8),
          if (equipment.category == 'sprayer') ...[
            Text('Mounting height (m): ${equipment.mountingHeight ?? '-'}',
                softWrap: true),
            Text(
                'Distance lidar → nozzle (m): ${equipment.lidarNozzleDistance ?? '-'}',
                softWrap: true),
            Text(
                'Ultrasonic distance (m): ${equipment.ultrasonicDistance ?? '-'}',
                softWrap: true),
            Text('Hinge → Axle (m): ${equipment.hingeToAxle ?? '-'}',
                softWrap: true),
            Text('Hinge → Nozzle (m): ${equipment.hingeToNozzle ?? '-'}',
                softWrap: true),
            Text(
                'Hinge → Control unit (m): ${equipment.hingeToControlUnit ?? '-'}',
                softWrap: true),
            const SizedBox(height: 8),
          ] else if (equipment.category == 'tractor') ...[
            Text('Wheel diameter (m): ${equipment.wheelDiameter ?? '-'}',
                softWrap: true),
            Text('Screws in wheel: ${equipment.screwsInWheel ?? '-'}',
                softWrap: true),
            Text('Axle length (m): ${equipment.axleLength ?? '-'}',
                softWrap: true),
            const SizedBox(height: 8),
          ],
          if (equipment.category == 'control_unit') ...[
            Text('MAC address: ${equipment.macAddress ?? '-'}', softWrap: true),
            Text('Linked sprayer: ${equipment.linkedSprayerId ?? '-'}',
                softWrap: true),
            Text('Linked tractor: ${equipment.linkedTractorId ?? '-'}',
                softWrap: true),
            Text(
                'Distance sensor→nozzle (m): ${equipment.lidarNozzleDistance ?? '-'}',
                softWrap: true),
            Text(
                'Mounting height of lidar (m): ${equipment.mountingHeight ?? '-'}',
                softWrap: true),
            Text(
                'Ultrasonic distance (m): ${equipment.ultrasonicDistance ?? '-'}',
                softWrap: true),
            const SizedBox(height: 8),
          ],
        ]),
      ),
    );
  }
}
