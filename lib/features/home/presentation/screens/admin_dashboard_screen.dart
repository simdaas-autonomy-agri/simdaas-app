import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/core/utils/error_utils.dart';
import '../../../job_planner/presentation/providers/job_providers.dart';
import '../../../job_planner/domain/entities/job.dart';
import '../../../auth/presentation/providers/users_providers.dart'
    as users_providers;
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;
import '../../../job_planner/presentation/screens/job_planner_screen.dart'
    show PlotPreviewPainter;
import '../../../job_planner/presentation/screens/job_planner_screen.dart'
    show JobPlannerScreen;
import '../../../plot_mapping/presentation/screens/plot_list_screen.dart'
    show PlotListScreen;
import '../../../data_monitoring/presentation/screens/monitoring_screen.dart';
import 'reports_screen.dart';
import '../../../auth/presentation/screens/operator_list_screen.dart'
    show OperatorListScreen;

enum _SortBy { time, status, supervisor }

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  _SortBy _sortBy = _SortBy.time;

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    final jobsAsync = ref.watch(jobsListProvider(userId));
    final fieldsAsync = ref.watch(fm_providers.plotsListProvider(userId));
    final usersAsync = ref.watch(users_providers.usersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 12),
          Text('Signed in as $userId'),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Jobs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            PopupMenuButton<_SortBy>(
              onSelected: (v) => setState(() => _sortBy = v),
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: _SortBy.time, child: Text('Sort by time')),
                const PopupMenuItem(
                    value: _SortBy.status, child: Text('Sort by status')),
                const PopupMenuItem(
                    value: _SortBy.supervisor,
                    child: Text('Sort by supervisor')),
              ],
              child: const Icon(Icons.sort),
            ),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: jobsAsync.when(
              data: (jobs) {
                return usersAsync.when(
                  data: (users) {
                    return fieldsAsync.when(
                      data: (fields) {
                        if (jobs.isEmpty)
                          return const Center(child: Text('No jobs yet'));
                        // Sort jobs
                        final sortedJobs = [...jobs];
                        sortedJobs.sort((a, b) {
                          switch (_sortBy) {
                            case _SortBy.time:
                              final ta = a.scheduleTime ?? a.createdAt;
                              final tb = b.scheduleTime ?? b.createdAt;
                              return ta.compareTo(tb);
                            case _SortBy.status:
                              return a.status.index.compareTo(b.status.index);
                            case _SortBy.supervisor:
                              return a.userId.compareTo(b.userId);
                          }
                        });

                        return ListView.separated(
                          itemCount: sortedJobs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final job = sortedJobs[i];
                            final plot = fields
                                .cast<fm_models.PlotModel?>()
                                .firstWhere((f) => f?.id == job.plotId,
                                    orElse: () => null);
                            // Try to resolve supervisor display from users list
                            String supervisorDisplay() {
                              try {
                                final found =
                                    users.cast<dynamic>().firstWhere((u) {
                                  try {
                                    return u?.id == job.userId;
                                  } catch (_) {
                                    try {
                                      return (u
                                              as Map<String, dynamic>)['id'] ==
                                          job.userId;
                                    } catch (_) {
                                      return false;
                                    }
                                  }
                                }, orElse: () => null);
                                if (found != null) {
                                  final data = found is Map<String, dynamic>
                                      ? found
                                      : (found.data() as Map<String, dynamic>?);
                                  final name = data?['name'] as String?;
                                  final email = data?['email'] as String?;
                                  if (name != null && name.isNotEmpty)
                                    return name;
                                  return email ?? job.userId;
                                }
                              } catch (_) {}
                              return job.userId;
                            }

                            // Responsive tile: side-by-side on wide screens, stacked on narrow
                            return LayoutBuilder(
                                builder: (context, tileConstraints) {
                              final narrow = tileConstraints.maxWidth < 520;
                              final details = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(job.name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Supervisor: ${supervisorDisplay()}',
                                          style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${plot?.name ?? 'Unknown farm'}'),
                                  Text('Spray rate: ${job.sprayRate ?? '-'}'),
                                ],
                              );

                              final statusPreview = Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Chip(
                                    label: Text(
                                      job.status
                                          .toString()
                                          .split('.')
                                          .last
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: job.status ==
                                            JobStatus.scheduled
                                        ? Colors.orange
                                        : job.status == JobStatus.ongoing
                                            ? Colors.green
                                            : job.status == JobStatus.delayed
                                                ? Colors.red
                                                : Colors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 72,
                                    height: 48,
                                    child:
                                        plot != null && plot.polygon.isNotEmpty
                                            ? CustomPaint(
                                                painter: PlotPreviewPainter(
                                                    plot.polygon))
                                            : Container(
                                                color: Colors.grey.shade200),
                                  ),
                                ],
                              );

                              return GestureDetector(
                                onTap: () {
                                  final sta =
                                      (job.scheduleTime ?? job.createdAt);
                                  final isOngoing =
                                      !sta.isAfter(DateTime.now());
                                  if (isOngoing) {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => MonitoringScreen(
                                                plotId: job.plotId,
                                                jobId: job.id)));
                                  } else {
                                    Navigator.of(context).pushNamed('/jobs');
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 4.0),
                                  child: narrow
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            details,
                                            const SizedBox(height: 8),
                                            Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: statusPreview),
                                          ],
                                        )
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: details),
                                            const SizedBox(width: 12),
                                            statusPreview,
                                          ],
                                        ),
                                ),
                              );
                            });
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Center(child: Text(extractErrorMessage(e))),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(extractErrorMessage(e))),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(extractErrorMessage(e))),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 420;

            final buttons = <Widget>[
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (c) => const PlotListScreen(showFab: false))),
                  icon: const Icon(Icons.map),
                  label: const Text('Plots')),
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (c) => const JobPlannerScreen(showFab: false))),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Jobs')),
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (c) =>
                          const OperatorListScreen(showFab: false))),
                  icon: const Icon(Icons.person),
                  label: const Text('Operators')),
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamed('/equipments', arguments: {'readOnly': true}),
                  icon: const Icon(Icons.build),
                  label: const Text('Equipments')),
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (c) => const ReportsScreen())),
                  icon: const Icon(Icons.report),
                  label: const Text('Reports')),
              ElevatedButton.icon(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text('Help & Support'),
                            content: const Text(
                                'Helpline: +1-800-555-0123\nAvailable 9am-5pm'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'))
                            ],
                          )),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Help')),
            ];

            // Use GridView for denser layout. On narrow screens use 1 column, otherwise 2.
            final crossAxisCount = isNarrow ? 2 : 3;
            // Compute a childAspectRatio so that each button is roughly `targetHeight` tall.
            final spacing = 8.0;
            final targetHeight = 52.0;
            final cellWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;
            final childAspectRatio = cellWidth / targetHeight;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
              children: buttons
                  .map((b) => SizedBox(width: double.infinity, child: b))
                  .toList(),
            );
          }),
        ]),
      ),
    );
  }
}
