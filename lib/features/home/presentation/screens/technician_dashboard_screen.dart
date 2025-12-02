import 'package:flutter/material.dart';

class TechnicianDashboardScreen extends StatelessWidget {
  const TechnicianDashboardScreen({super.key});
  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
            'For support, contact your administrator or Call 1234567890.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make the grid responsive: single column on narrow screens, two on wider
    final isWide = MediaQuery.of(context).size.width > 600;
    final crossAxis = isWide ? 2 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings_outlined),
        //     onPressed: () => Navigator.of(context).pushNamed('/settings'),
        //     tooltip: 'Settings',
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: GridView.count(
          crossAxisCount: crossAxis,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 5 / 2,
          children: [
            _buildTile(
              context,
              icon: Icons.map,
              title: 'Plots',
              subtitle: 'View and manage plots',
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              onTap: () => Navigator.of(context).pushNamed('/plots'),
            ),
            _buildTile(
              context,
              icon: Icons.build_circle,
              title: 'Equipments',
              subtitle: 'Tools & sensors',
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.06),
              onTap: () =>
                  Navigator.of(context).pushNamed('/equipment_categories'),
            ),
            _buildTile(
              context,
              icon: Icons.help_outline,
              title: 'Help',
              subtitle: 'Support & docs',
              color: Theme.of(context).colorScheme.surface.withOpacity(0.04),
              onTap: () => _showHelp(context),
            ),
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
