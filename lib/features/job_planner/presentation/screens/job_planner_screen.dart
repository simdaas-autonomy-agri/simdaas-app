import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/job_providers.dart';
import '../providers/job_sort_provider.dart';
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;
import 'package:latlong2/latlong.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/core/widgets/api_error_widget.dart';
import '../../../data_monitoring/presentation/screens/monitoring_screen.dart';
// Note: we avoid fetching the global users list here to prevent extra
// /users API calls when rendering the jobs list. Showing userId is a
// lightweight fallback; detailed user info can still be shown on the
// Job Details screen which may fetch users on demand.
import 'job_details_screen.dart';
import '../../domain/entities/job.dart';
import 'dart:ui' as ui;

class JobPlannerScreen extends ConsumerWidget {
  final bool showFab;
  const JobPlannerScreen({super.key, this.showFab = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    final jobsAsync = ref.watch(jobsListProvider(userId));
    final plotsAsync = ref.watch(fm_providers.plotsListProvider(userId));
    final sortBy = ref.watch(jobListSortProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        elevation: 0,
        actions: [
          PopupMenuButton<SortBy>(
            onSelected: (v) =>
                ref.read(jobListSortProvider.notifier).setSortBy(v),
            icon: const Icon(Icons.sort),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: SortBy.time,
                  child: Row(
                    children: [
                      Icon(Icons.schedule),
                      SizedBox(width: 12),
                      Text('Sort by time'),
                    ],
                  )),
              const PopupMenuItem(
                  value: SortBy.status,
                  child: Row(
                    children: [
                      Icon(Icons.flag),
                      SizedBox(width: 12),
                      Text('Sort by status'),
                    ],
                  )),
              const PopupMenuItem(
                  value: SortBy.supervisor,
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 12),
                      Text('Sort by supervisor'),
                    ],
                  )),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Signed in as $userId',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: jobsAsync.when(
              data: (jobs) {
                return plotsAsync.when(
                  data: (plots) {
                    if (jobs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No jobs yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to create your first job',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Sort jobs (work on a copy)
                    final sortedJobs = [...jobs];
                    sortedJobs.sort((a, b) {
                      switch (sortBy) {
                        case SortBy.time:
                          final ta = a.scheduleTime ?? a.createdAt;
                          final tb = b.scheduleTime ?? b.createdAt;
                          return ta.compareTo(tb);
                        case SortBy.status:
                          // Sort by server-provided status (enum ordering)
                          return a.status.index.compareTo(b.status.index);
                        case SortBy.supervisor:
                          return a.userId.compareTo(b.userId);
                      }
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: sortedJobs.length,
                      itemBuilder: (context, i) {
                        final job = sortedJobs[i];
                        final plot =
                            plots.cast<fm_models.PlotModel?>().firstWhere(
                                  (f) => f?.id == job.plotId,
                                  orElse: () => null,
                                );

                        String supervisorDisplay() => job.userId;
                        final jobStatus = job.status;
                        // Map server-provided status to UI colors
                        final Color statusColor;
                        switch (jobStatus) {
                          case JobStatus.ongoing:
                            statusColor = const Color(0xFF2E7D32); // Green
                            break;
                          case JobStatus.scheduled:
                            statusColor = const Color(0xFF8E4600); // Amber
                            break;
                          case JobStatus.completed:
                            statusColor = Colors.grey; // Completed
                            break;
                          case JobStatus.delayed:
                            statusColor = Colors.red; // Delayed / error
                            break;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              if (jobStatus == JobStatus.ongoing) {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => MonitoringScreen(
                                        plotId: job.plotId, jobId: job.id)));
                                return;
                              }
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => JobDetailsScreen(job: job)));
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              job.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  supervisorDisplay(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          jobStatus
                                              .toString()
                                              .split('.')
                                              .last
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (plot != null &&
                                          plot.polygon.isNotEmpty)
                                        Container(
                                          width: 80,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.3),
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CustomPaint(
                                              painter: PlotPreviewPainter(
                                                  plot.polygon),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 80,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.map_outlined,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    plot?.name ??
                                                        'Unknown farm',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.water_drop_outlined,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Rate: ${job.sprayRate ?? '-'}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.science_outlined,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Mix: ${job.productMix ?? '-'}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => ApiErrorWidget(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(fm_providers.plotsListProvider(userId)),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => ApiErrorWidget(
                error: e,
                onRetry: () => ref.invalidate(jobsListProvider(userId)),
              ),
            ),
          ),
        ]),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed('/create_job'),
              icon: const Icon(Icons.add),
              label: const Text('Create Job'),
            )
          : null,
    );
  }
}

class PlotPreviewPainter extends CustomPainter {
  final List<LatLng> points;
  PlotPreviewPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    // Normalize lat/lng into box
    final lats = points.map((p) => p.latitude).toList();
    final lngs = points.map((p) => p.longitude).toList();
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final latRange = (maxLat - minLat) == 0 ? 1e-6 : (maxLat - minLat);
    final lngRange = (maxLng - minLng) == 0 ? 1e-6 : (maxLng - minLng);
    final uiPath = ui.Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = ((p.longitude - minLng) / lngRange) * size.width;
      final y = size.height - ((p.latitude - minLat) / latRange) * size.height;
      if (i == 0)
        uiPath.moveTo(x, y);
      else
        uiPath.lineTo(x, y);
    }
    uiPath.close();
    final paintFill = Paint()..color = Colors.green.withOpacity(0.25);
    final paintBorder = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(uiPath, paintFill);
    canvas.drawPath(uiPath, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
