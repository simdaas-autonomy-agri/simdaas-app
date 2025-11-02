import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../../../job_planner/presentation/providers/job_providers.dart';
import '../../../data_monitoring/presentation/screens/monitoring_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (userId != null) Text('Signed in as $userId'),
          const SizedBox(height: 12),
          Expanded(
            child: userId == null
                ? const Center(child: Text('No user signed in'))
                : ref.watch(jobsListProvider(userId)).when(
                      data: (jobs) {
                        if (jobs.isEmpty) {
                          return const Center(child: Text('No jobs yet'));
                        }
                        return ListView.separated(
                          itemCount: jobs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final job = jobs[i];
                            final dt = job.scheduleTime ?? job.createdAt;
                            final now = DateTime.now();
                            final status = dt.isAfter(now)
                                ? 'scheduled'
                                : dt.isBefore(
                                        now.subtract(const Duration(hours: 1)))
                                    ? 'completed'
                                    : 'ongoing';
                            Color statusColor = status == 'scheduled'
                                ? Colors.orange
                                : status == 'ongoing'
                                    ? Colors.green
                                    : status == 'delayed'
                                        ? Colors.red
                                        : Colors.grey;

                            return ListTile(
                              title: Text(job.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'When: ${dt.toLocal().toIso8601String().replaceFirst('T', ' ')}'),
                                  Text('Spray rate: ${job.sprayRate ?? '-'}'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                    status.replaceAll('_', ' ').toUpperCase(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                                backgroundColor: statusColor,
                              ),
                              onTap: () {
                                if (status == 'ongoing') {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => MonitoringScreen(
                                          plotId: job.plotId, jobId: job.id)));
                                } else {
                                  Navigator.of(context).pushNamed('/jobs');
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) =>
                          Center(child: Text('Error loading jobs: $e')),
                    ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/plots'),
                  icon: const Icon(Icons.map),
                  label: const Text('Plots')),
              ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/monitoring'),
                  icon: const Icon(Icons.monitor),
                  label: const Text('Data Monitoring')),
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/jobs'),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Jobs')),
              ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/applications'),
                  icon: const Icon(Icons.science),
                  label: const Text('Applications')),
              ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/equipments'),
                  icon: const Icon(Icons.build),
                  label: const Text('Equipments')),
              ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/create_job'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Job')),
              ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout')),
            ],
          ),
        ]),
      ),
    );
  }
}
