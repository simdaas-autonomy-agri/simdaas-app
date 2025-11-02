import 'package:flutter/material.dart';
import '../../../home/presentation/screens/reports_screen.dart';

class JobSupervisorDashboardScreen extends StatelessWidget {
  const JobSupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Make the grid responsive similar to Technician dashboard
    final isWide = MediaQuery.of(context).size.width > 600;
    final crossAxis = isWide ? 2 : 1;

    void openReports() {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (c) => const ReportsScreen()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Job Supervisor')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: GridView.count(
          crossAxisCount: crossAxis,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 5 / 2,
          children: [
            _buildTile(context,
                icon: Icons.schedule,
                title: 'Job Schedule',
                subtitle: 'View upcoming jobs',
                color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                onTap: () => Navigator.of(context).pushNamed('/jobs')),
            _buildTile(context,
                icon: Icons.add,
                title: 'Create Job',
                subtitle: 'Create new job',
                color:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.06),
                onTap: () => Navigator.of(context).pushNamed('/create_job')),
            _buildTile(context,
                icon: Icons.report,
                title: 'Job Reports',
                subtitle: 'View job reports',
                color: Theme.of(context).colorScheme.surface.withOpacity(0.04),
                onTap: openReports),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color? color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.all(12),
                child: Icon(icon,
                    size: 36, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
