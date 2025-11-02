import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SimDaaS')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/admin_dashboard'),
              child: const SizedBox(
                  width: double.infinity, child: Center(child: Text('Admin'))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/jobs'),
              child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text('Job Supervisor'))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/monitoring'),
              child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text('Agricultural Technician'))),
            ),
          ],
        ),
      ),
    );
  }
}
