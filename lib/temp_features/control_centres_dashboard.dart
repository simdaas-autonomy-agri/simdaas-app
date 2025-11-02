import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/equipments/presentation/providers/equipment_providers.dart'
    as eq_provs;
import '../features/plot_mapping/presentation/providers/plot_providers.dart'
    as fm_provs;
import '../core/services/auth_service.dart';

/// Temporary dashboard that resembles the main three-button dashboard but
/// includes a quick control-centres status card for development/testing.
class TempDashboard extends ConsumerWidget {
  const TempDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId ?? '';
    final controlUnitsAsync = ref.watch(eq_provs.controlUnitsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.dashboard_customize,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome!',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Select the area you want to access',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Control centres status card
                controlUnitsAsync.when(
                  data: (items) => _DashboardCard(
                    icon: Icons.router_outlined,
                    title: 'Active Devices',
                    subtitle: _controlSummary(items),
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => _ControlUnitsListScreen(items: items))),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => _DashboardCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'Active Devices',
                    subtitle: 'Error loading control centres',
                    color: Colors.red,
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 16),
                _DashboardCard(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Configure equipment and system',
                  color: const Color(0xFF8E4600),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/technician_dashboard'),
                ),
                // const SizedBox(height: 16),
                // _DashboardCard(
                //   icon: Icons.app_settings_alt_outlined,
                //   title: 'App Settings',
                //   subtitle: 'Manage application preferences',
                //   color: const Color(0xFF00796B),
                //   onTap: () => Navigator.of(context).pushNamed('/app_settings'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _controlSummary(List items) {
    if (items.isEmpty) return 'No control centres';
    final statuses = <String, int>{};
    for (final it in items) {
      final s = (it.status ?? 'unknown').toString().toLowerCase();
      statuses[s] = (statuses[s] ?? 0) + 1;
    }
    final parts =
        statuses.entries.map((e) => '${_capitalize(e.key)}: ${e.value}');
    return parts.join(' • ');
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ControlUnitsListScreen extends ConsumerWidget {
  final List items;
  const _ControlUnitsListScreen({required this.items, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId ?? '';
    final plotsAsync = ref.watch(fm_provs.plotsListProvider(userId));

    // Build a quick mapping of plot id -> plot name when available.
    final Map<String, String> plotMap = {};
    final plots = plotsAsync.asData?.value;
    if (plots != null) {
      for (final p in plots) {
        try {
          plotMap[p.id.toString()] = p.name;
        } catch (_) {
          // ignore malformed plot objects
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Active Devices')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final cu = items[i];
          final linkedPlotId = (cu.linkedPlotId ?? '').toString();
          final linkedPlotName = plotMap[linkedPlotId];

          return ListTile(
            title: Text(cu.name ?? 'Unnamed'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((cu.controlUnitId ?? '').isNotEmpty)
                  Text('ID: ${cu.controlUnitId}'),
                if (linkedPlotId.isNotEmpty)
                  Text('Default plot: ${linkedPlotName ?? linkedPlotId}'),
                Text('Status: ${cu.status ?? 'unknown'}'),
              ],
            ),
            trailing: Icon(
              _iconForStatus(cu.status),
              color: _colorForStatus(cu.status),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
      case 'occupied':
        return Icons.check_circle;
      case 'offline':
      case 'vacant':
        return Icons.pause_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _colorForStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
      case 'occupied':
        return Colors.green;
      case 'offline':
      case 'vacant':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
