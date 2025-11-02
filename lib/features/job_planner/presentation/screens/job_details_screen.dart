import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;
import '../../../data_monitoring/presentation/screens/monitoring_screen.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/job.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../screens/edit_job_screen.dart';
import '../../data/models/job_model.dart';
import '../../../auth/presentation/providers/users_providers.dart'
    as users_providers;
import 'dart:ui' as ui;

class JobDetailsScreen extends ConsumerWidget {
  final JobEntity job;

  const JobDetailsScreen({super.key, required this.job});

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return Colors.orange;
      case JobStatus.ongoing:
        return Colors.green;
      case JobStatus.completed:
        return Colors.grey;
      case JobStatus.delayed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    final plotsAsync = ref.watch(fm_providers.plotsListProvider(userId));
    final usersAsync = ref.watch(users_providers.usersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: plotsAsync.when(
          data: (plots) {
            final plot = plots
                .cast<fm_models.PlotModel?>()
                .firstWhere((p) => p?.id == job.plotId, orElse: () => null);

            return usersAsync.when(
              data: (users) {
                // (removed unused supervisorDisplay helper)

                String operatorDisplay() {
                  try {
                    final found = users.cast<dynamic>().firstWhere((u) {
                      try {
                        return u?.id == job.operatorId;
                      } catch (_) {
                        try {
                          return (u as Map<String, dynamic>)['id'] ==
                              job.operatorId;
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
                      if (name != null && name.isNotEmpty) return name;
                      return email ?? job.operatorId ?? '-';
                    }
                  } catch (_) {}
                  return job.operatorId ?? '-';
                }

                final status = job.status;

                // Build the content sections
                final content = SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: job name + actions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(job.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                                status
                                    .toString()
                                    .split('.')
                                    .last
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: _statusColor(status),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Start -> open monitoring view for this job
                              if (job.plotId != null) {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => MonitoringScreen(
                                        plotId: job.plotId, jobId: job.id)));
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Edit -> build JobModel and push edit screen
                              final m = JobModel(
                                id: job.id,
                                name: job.name,
                                userId: job.userId,
                                plotId: job.plotId,
                                controlUnitId: job.controlUnitId,
                                createdAt: job.createdAt,
                                scheduleTime: job.scheduleTime,
                                operatorId: job.operatorId,
                                sprayRate: job.sprayRate,
                                productMix: job.productMix,
                                status: job.status,
                              );
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => EditJobScreen(jobModel: m)));
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Plot section
                      const Text('Plot',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plot?.name ?? 'Unknown plot',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    if (plot?.area != null)
                                      Text(
                                          'Area: ${plot!.area!.toStringAsFixed(2)} ha'),
                                    if (plot?.treeCount != null)
                                      Text('Trees: ${plot!.treeCount}'),
                                    if (plot?.rowSpacing != null)
                                      Text(
                                          'Row spacing: ${plot!.rowSpacing} m'),
                                    Text(
                                        'Bed Height: ${plot?.bedHeight != null ? '${plot!.bedHeight} m' : '-'}'),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                height: 90,
                                child: plot != null && plot.polygon.isNotEmpty
                                    ? CustomPaint(
                                        painter:
                                            _PlotPreviewPainter(plot.polygon))
                                    : Container(color: Colors.grey.shade200),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Equipments section
                      const Text('Equipments',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Control Unit: ${job.controlUnitId ?? '-'}'),
                                const SizedBox(height: 6),
                                Text('User: ${job.userId}'),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Operator section
                      const Text('Operator',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(operatorDisplay()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Spraying details
                      const Text('Spraying details',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (job.sprayRate != null)
                                  Text('Spray Rate: ${job.sprayRate}'),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Product mix / materials
                      const Text('Product mix',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: job.productMix == null ||
                                  job.productMix!.isEmpty
                              ? const Text('No products/mix recorded')
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: job.productMix!
                                      .map((m) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6.0),
                                            child: Text(
                                                '${m['name'] ?? ''} — qty: ${m['quantity'] ?? ''}, water: ${m['waterQuantity'] ?? ''}, rate: ${m['sprayingRate'] ?? ''} ${m['sprayingRateUnit'] ?? ''}'),
                                          ))
                                      .toList(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );

                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: content),
                    ]);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Users error: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Plots error: $e')),
        ),
      ),
    );
  }
}

class _PlotPreviewPainter extends CustomPainter {
  final List<LatLng> points;
  _PlotPreviewPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
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
