import 'package:flutter/material.dart';

/// A small, focused dashboard that presents three role buttons.
/// This will be used as the default `/dashboard` route and simply
/// forwards the user to the appropriate area (admin, jobs, monitoring).
class ThreeButtonDashboardScreen extends StatelessWidget {
  const ThreeButtonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimDaaS'),
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
                const SizedBox(height: 48),
                // _DashboardCard(
                //   icon: Icons.analytics_outlined,
                //   title: 'Dashboard',
                //   subtitle: 'View reports and analytics',
                //   color: const Color(0xFF015685), // Planned Blue
                //   onTap: () =>
                //       Navigator.of(context).pushNamed('/admin_dashboard'),
                // ),
                // const SizedBox(height: 16),
                // _DashboardCard(
                //   icon: Icons.work_outline,
                //   title: 'Jobs',
                //   subtitle: 'Manage and schedule jobs',
                //   color: const Color(0xFF2E7D32), // Primary Green
                //   onTap: () => Navigator.of(context)
                //       .pushNamed('/job_supervisor_dashboard'),
                // ),
                const SizedBox(height: 16),
                _DashboardCard(
                  icon: Icons.settings_outlined,
                  title: 'Technical Settings',
                  subtitle: 'Configure equipment and system',
                  color: const Color(0xFF8E4600), // Scheduled Amber
                  onTap: () =>
                      Navigator.of(context).pushNamed('/technician_dashboard'),
                ),
                const SizedBox(height: 16),
                _DashboardCard(
                  icon: Icons.app_settings_alt_outlined,
                  title: 'App Settings',
                  subtitle: 'Manage application preferences',
                  color: const Color(0xFF00796B), // Secondary Teal
                  onTap: () => Navigator.of(context).pushNamed('/app_settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
