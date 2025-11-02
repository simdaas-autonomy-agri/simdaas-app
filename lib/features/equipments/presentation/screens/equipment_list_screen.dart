import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/equipment_providers.dart';
// ...existing code...
import 'create_equipment_screen.dart';
import 'equipment_details_screen.dart';
import 'create_control_unit_screen.dart';
import 'scan_control_unit_screen.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/core/widgets/api_error_widget.dart';

/// Equipment list screen with three category buttons and a filtered list.
class EquipmentListScreen extends ConsumerStatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  ConsumerState<EquipmentListScreen> createState() =>
      _EquipmentListScreenState();
}

class _EquipmentListScreenState extends ConsumerState<EquipmentListScreen> {
  String _filterCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final readOnly = args is Map && args['readOnly'] == true;

    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    final routeCategory = (args is Map && args['category'] is String)
        ? args['category'] as String
        : null;

    // If a specific category was requested via route args, use the dedicated
    // provider so we only fetch that category's endpoint. Otherwise fetch
    // the merged equipments list.
    final itemsAsync = routeCategory == null
        ? ref.watch(equipmentsListProvider(userId))
        : (routeCategory.toLowerCase() == 'control_unit'
            ? ref.watch(controlUnitsProvider(userId))
            : (routeCategory.toLowerCase() == 'tractor'
                ? ref.watch(tractorsProvider(userId))
                : ref.watch(sprayersProvider(userId))));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipments'),
        elevation: 0,
      ),
      body: itemsAsync.when(
        data: (items) {
          final activeCategory = routeCategory ?? _filterCategory;

          final filtered = items.where((it) {
            final e = it as dynamic;
            final cat = (e.category as String?) ?? 'other';
            if (activeCategory == 'all') return true;
            return cat.toLowerCase() == activeCategory.toLowerCase();
          }).toList();

          return Column(
            children: [
              if (routeCategory == null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.memory,
                          label: 'Control Units',
                          color: const Color(0xFF015685), // Planned Blue
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const EquipmentListScreen(),
                                  settings: RouteSettings(arguments: {
                                    'category': 'control_unit',
                                    'readOnly': readOnly
                                  }))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.agriculture,
                          label: 'Tractors',
                          color: const Color(0xFF2E7D32), // Primary Green
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const EquipmentListScreen(),
                                  settings: RouteSettings(arguments: {
                                    'category': 'tractor',
                                    'readOnly': readOnly
                                  }))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.water_drop,
                          label: 'Sprayers',
                          color: const Color(0xFF8E4600), // Scheduled Amber
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const EquipmentListScreen(),
                                  settings: RouteSettings(arguments: {
                                    'category': 'sprayer',
                                    'readOnly': readOnly
                                  }))),
                        ),
                      ),
                    ],
                  ),
                ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No equipment yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add equipment',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (c, i) {
                      final e = filtered[i];

                      final status = (e.status ?? 'vacant').toLowerCase();
                      final isAssigned = status != 'vacant';

                      final details = (e.category == 'sprayer')
                          ? 'Mount H: ${e.mountingHeight ?? '-'} m • Lidar-Nozzle: ${e.lidarNozzleDistance ?? '-'} m'
                          : e.category;

                      IconData getCategoryIcon(String category) {
                        switch (category.toLowerCase()) {
                          case 'control_unit':
                            return Icons.memory;
                          case 'tractor':
                            return Icons.agriculture;
                          case 'sprayer':
                            return Icons.water_drop;
                          default:
                            return Icons.precision_manufacturing;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: InkWell(
                          onTap: () async {
                            final res = await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => EquipmentDetailsScreen(
                                        equipment: e, readOnly: readOnly)));
                            if (res == true) {
                              final currentUserId =
                                  ref.read(authServiceProvider).currentUserId ??
                                      'demo_user';
                              ref.invalidate(
                                  equipmentsListProvider(currentUserId));
                              switch (e.category.toLowerCase()) {
                                case 'control_unit':
                                  ref.invalidate(
                                      controlUnitsProvider(currentUserId));
                                  break;
                                case 'sprayer':
                                  ref.invalidate(
                                      sprayersProvider(currentUserId));
                                  break;
                                case 'tractor':
                                  ref.invalidate(
                                      tractorsProvider(currentUserId));
                                  break;
                                default:
                                  break;
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    getCategoryIcon(e.category),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        details,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAssigned
                                        ? const Color(0xFFAA2424)
                                            .withOpacity(0.1) // Warning Red
                                        : const Color(0xFF2E7D32)
                                            .withOpacity(0.1), // Primary Green
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: isAssigned
                                          ? const Color(
                                              0xFFAA2424) // Warning Red
                                          : const Color(
                                              0xFF2E7D32), // Primary Green
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ApiErrorWidget(
          error: e,
          onRetry: () => ref.invalidate(equipmentsListProvider(userId)),
        ),
      ),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final args = ModalRoute.of(context)?.settings.arguments;
                final routeCategory =
                    (args is Map && args['category'] is String)
                        ? args['category'] as String
                        : null;

                // If category is control_unit offer a scan option first
                if (routeCategory != null) {
                  // Navigate to category-specific create pages
                  if (routeCategory.toLowerCase() == 'control_unit') {
                    final choice = await showModalBottomSheet<String>(
                        context: context,
                        builder: (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.qr_code_scanner),
                                  title: const Text('Scan to add'),
                                  onTap: () =>
                                      Navigator.of(context).pop('scan'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.add),
                                  title: const Text('Add control unit'),
                                  onTap: () => Navigator.of(context).pop('add'),
                                ),
                              ],
                            ));
                    if (choice == 'scan') {
                      // push scanner, get data back and open create with prefill
                      final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ScanControlUnitScreen()));
                      if (result is Map<String, dynamic>) {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                CreateControlUnitScreen(existingData: result)));
                      }
                    } else {
                      await Navigator.of(context)
                          .pushNamed('/create_control_unit');
                    }
                  } else if (routeCategory.toLowerCase() == 'tractor') {
                    await Navigator.of(context).pushNamed('/create_tractor');
                  } else if (routeCategory.toLowerCase() == 'sprayer') {
                    await Navigator.of(context).pushNamed('/create_sprayer');
                  } else {
                    // Fallback to generic creator if unknown category
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CreateEquipmentScreen(
                              existingData: {'category': routeCategory},
                            )));
                  }
                } else {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CreateEquipmentScreen()));
                }

                ref.invalidate(equipmentsListProvider(userId));
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Equipment'),
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
