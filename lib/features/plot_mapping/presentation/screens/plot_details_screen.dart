import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/core/utils/error_utils.dart';
// job providers intentionally not imported here to avoid circular deps
import '../../domain/entities/plot.dart';
// avoid importing plot_list_screen to prevent a circular import; reimplement a small preview widget here
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../data/models/plot_model.dart';
import '../providers/plot_providers.dart';

class PlotPreview extends StatelessWidget {
  final List<LatLng> polygon;
  final double width;
  final double height;
  const PlotPreview(
      {super.key, required this.polygon, this.width = 300, this.height = 200});

  @override
  Widget build(BuildContext context) {
    if (polygon.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child:
            const Center(child: Icon(Icons.map, size: 28, color: Colors.grey)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: CustomPaint(
          painter: PlotPolygonPainter(polygon),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class PlotPolygonPainter extends CustomPainter {
  final List<LatLng> polygon;
  PlotPolygonPainter(this.polygon);

  @override
  void paint(Canvas canvas, Size size) {
    if (polygon.isEmpty) return;

    double minLat = double.infinity,
        maxLat = -double.infinity,
        minLng = double.infinity,
        maxLng = -double.infinity;
    for (final p in polygon) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    final latPad = (maxLat - minLat) * 0.1;
    final lngPad = (maxLng - minLng) * 0.1;
    if (latPad == 0 && lngPad == 0) {
      final paint = ui.Paint()..color = Colors.blue;
      final cx = size.width / 2;
      final cy = size.height / 2;
      canvas.drawCircle(ui.Offset(cx, cy), 4.0, paint);
      return;
    }

    minLat -= latPad;
    maxLat += latPad;
    minLng -= lngPad;
    maxLng += lngPad;

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();

    double scaleX = size.width / (lngSpan == 0 ? 1 : lngSpan);
    double scaleY = size.height / (latSpan == 0 ? 1 : latSpan);
    final scale = math.min(scaleX, scaleY);

    final usedWidth = (lngSpan) * scale;
    final usedHeight = (latSpan) * scale;
    final offsetX = (size.width - usedWidth) / 2;
    final offsetY = (size.height - usedHeight) / 2;

    final path = ui.Path();
    for (int i = 0; i < polygon.length; i++) {
      final p = polygon[i];
      final x = offsetX + ((p.longitude - minLng) * scale);
      final y = offsetY + usedHeight - ((p.latitude - minLat) * scale);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();

    final fill = ui.Paint()
      ..color = Colors.blue.withOpacity(0.35)
      ..style = ui.PaintingStyle.fill;
    final stroke = ui.Paint()
      ..color = Colors.blue
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant PlotPolygonPainter oldDelegate) =>
      oldDelegate.polygon != polygon;
}

class PlotDetailsScreen extends ConsumerWidget {
  final PlotEntity plot;
  const PlotDetailsScreen({super.key, required this.plot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plot.name),
        actions: [
          IconButton(
            tooltip: 'Edit plot details',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final nameCtrl = TextEditingController(text: plot.name);
              final areaCtrl =
                  TextEditingController(text: plot.area?.toString() ?? '');
              final bedCtrl =
                  TextEditingController(text: plot.bedHeight?.toString() ?? '');
              final rowCtrl = TextEditingController(
                  text: plot.rowSpacing?.toString() ?? '');
              final treeCtrl =
                  TextEditingController(text: plot.treeCount?.toString() ?? '');

              final res = await showModalBottomSheet<Map<String, String>?>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                builder: (ctx) {
                  final insets = MediaQuery.of(ctx).viewInsets.bottom;
                  final maxHeight = MediaQuery.of(ctx).size.height * 0.9;
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.only(bottom: insets),
                    child: FractionallySizedBox(
                      heightFactor: 0.75,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: Material(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          elevation: 8,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12))),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 12.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // small drag handle
                                  Center(
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                      controller: nameCtrl,
                                      decoration: const InputDecoration(
                                          labelText: 'Plot Name')),
                                  const SizedBox(height: 8),
                                  TextField(
                                      controller: areaCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                          labelText: 'Approx Area (ha)')),
                                  const SizedBox(height: 8),
                                  TextField(
                                      controller: rowCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                          labelText: 'Row Spacing (m)')),
                                  const SizedBox(height: 8),
                                  TextField(
                                      controller: bedCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: const InputDecoration(
                                          labelText: 'Bed Height (m)')),
                                  const SizedBox(height: 8),
                                  TextField(
                                      controller: treeCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText: 'Total Trees')),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop({
                                        'name': nameCtrl.text,
                                        'area': areaCtrl.text,
                                        'rowSpacing': rowCtrl.text,
                                        'bedHeight': bedCtrl.text,
                                        'treeCount': treeCtrl.text,
                                      });
                                    },
                                    child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12.0),
                                        child: Text('Save')),
                                  ),
                                  SizedBox(height: insets),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );

              if (res != null) {
                final repo = ref.read(plotRepoProvider);
                final updated = PlotModel(
                  id: plot.id,
                  name: res['name'] ?? plot.name,
                  userId: plot.userId,
                  polygon: plot.polygon,
                  bedHeight: double.tryParse(res['bedHeight'] ?? ''),
                  area: double.tryParse(res['area'] ?? ''),
                  rowSpacing: double.tryParse(res['rowSpacing'] ?? ''),
                  treeCount: int.tryParse(res['treeCount'] ?? ''),
                );
                try {
                  await repo.updatePlot(updated);
                  final currentUserId =
                      ref.read(authServiceProvider).currentUserId;
                  if (currentUserId != null)
                    ref.invalidate(plotsListProvider(currentUserId));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plot updated')));
                  // replace this route with a fresh details page for the updated plot
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => PlotDetailsScreen(plot: updated)));
                } catch (e) {
                  showPolishedError(context, e, fallback: 'Error updating plot');
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Delete plot',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete plot'),
                  content: const Text(
                      'Are you sure you want to delete this plot? This action cannot be undone.\nNote: Ensure you have not connected this plot to any equipment.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              final repo = ref.read(plotRepoProvider);
              try {
                await repo.deletePlot(plot.id);
                final currentUserId =
                    ref.read(authServiceProvider).currentUserId;
                if (currentUserId != null) {
                  ref.invalidate(plotsListProvider(currentUserId));
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plot deleted')));
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  showPolishedError(context, e, fallback: 'Error deleting plot');
                }
              }
            },
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Top preview as a simple sliver
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: LayoutBuilder(builder: (ctx, bc) {
                  final maxWidth = bc.maxWidth;
                  final previewWidth = maxWidth < 520 ? maxWidth * 0.9 : 520.0;
                  return SizedBox(
                    width: previewWidth,
                    height: previewWidth * 0.56,
                    child: PlotPreview(
                        polygon: plot.polygon,
                        width: previewWidth,
                        height: previewWidth * 0.56),
                  );
                }),
              ),
            ),
          ),

          // Sticky plot summary header
          SliverPersistentHeader(
            pinned: true,
            delegate: _PlotSummaryHeader(plot: plot),
          ),

          // // Jobs title
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding:
          //         const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          //     child: const Text('Jobs',
          //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          //   ),
          // ),

          // // Jobs list built from provider
          // Builder(builder: (context) {
          //   final uid = ref.read(authServiceProvider).currentUserId;
          //   if (uid == null) {
          //     return const SliverToBoxAdapter(
          //         child: Padding(
          //             padding: EdgeInsets.all(12),
          //             child: Text('Not signed in')));
          //   }
          //   final jobsAsync = ref.watch(jobsListProvider(uid));

          //   final jobChildren = jobsAsync.when<List<Widget>>(
          //     data: (jobs) {
          //       final filtered =
          //           jobs.where((j) => j.plotId == plot.id).toList();
          //       if (filtered.isEmpty)
          //         return [
          //           const Padding(
          //               padding: EdgeInsets.all(12),
          //               child: Text('No jobs for this plot'))
          //         ];

          //       final now = DateTime.now();

          //       return List.generate(filtered.length, (i) {
          //         final job = filtered[i];
          //         // reuse the same row UI
          //         final status = job.status;
          //         final scheduledTime = job.scheduleTime ?? job.createdAt;
          //         final isOngoing = !scheduledTime.isAfter(now);

          //         String mixSummary() {
          //           try {
          //             if (job.productMix == null || job.productMix!.isEmpty)
          //               return '-';
          //             final first = job.productMix!.first;
          //             final name = first['name'] ?? first['product'] ?? '';
          //             final qty = first['quantity'] ?? first['qty'] ?? '';
          //             return '$name ${qty != '' ? '• qty: $qty' : ''}';
          //           } catch (_) {
          //             return '-';
          //           }
          //         }

          //         return Padding(
          //           padding: const EdgeInsets.symmetric(
          //               horizontal: 12.0, vertical: 8.0),
          //           child: InkWell(
          //             onTap: () {
          //               if (!isOngoing) {
          //                 Navigator.of(context).push(MaterialPageRoute(
          //                     builder: (_) => JobDetailsScreen(job: job)));
          //                 return;
          //               }
          //               Navigator.of(context).push(MaterialPageRoute(
          //                   builder: (_) => MonitoringScreen(
          //                       plotId: job.plotId, jobId: job.id)));
          //             },
          //             child: Row(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 Expanded(
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Row(
          //                         children: [
          //                           Expanded(
          //                             child: Text(job.name,
          //                                 style: const TextStyle(
          //                                     fontSize: 16,
          //                                     fontWeight: FontWeight.bold)),
          //                           ),
          //                           const SizedBox(width: 8),
          //                           Chip(
          //                             label: Text(
          //                                 status
          //                                     .toString()
          //                                     .split('.')
          //                                     .last
          //                                     .replaceAll('_', ' ')
          //                                     .toUpperCase(),
          //                                 style: const TextStyle(
          //                                     color: Colors.white)),
          //                             backgroundColor: _statusColor(status),
          //                           ),
          //                         ],
          //                       ),
          //                       const SizedBox(height: 6),
          //                       Text(
          //                           'When: ${scheduledTime.toLocal().toString().split('.').first}'),
          //                       const SizedBox(height: 4),
          //                       Text(
          //                           'Spray: ${job.sprayRate ?? '-'} • Mix: ${mixSummary()}'),
          //                     ],
          //                   ),
          //                 ),
          //                 const SizedBox(width: 12),
          //                 SizedBox(
          //                     width: 84,
          //                     height: 56,
          //                     child: plot.polygon.isNotEmpty
          //                         ? CustomPaint(
          //                             painter: PlotPolygonPainter(plot.polygon))
          //                         : Container(color: Colors.grey.shade200)),
          //               ],
          //             ),
          //           ),
          //         );
          //       });
          //     },
          //     loading: () => [
          //       const Center(
          //           child: Padding(
          //               padding: EdgeInsets.all(12),
          //               child: CircularProgressIndicator()))
          //     ],
          //     error: (e, st) => [
          //       Padding(
          //           padding: const EdgeInsets.all(12),
          //           child: Text('Error loading jobs: $e'))
          //     ],
          //   );

          //   return SliverList(delegate: SliverChildListDelegate(jobChildren));
          // }),
        ],
      ),
    );
  }
}

class _PlotSummaryHeader extends SliverPersistentHeaderDelegate {
  final PlotEntity plot;
  _PlotSummaryHeader({required this.plot});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // responsive layout: two-column on wide screens, stacked on narrow
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: LayoutBuilder(builder: (ctx, bc) {
        final narrow = bc.maxWidth < 520;
        final card = Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: narrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildFields(context))
                : Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildFields(context))),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 140,
                        height: 90,
                        child: plot.polygon.isNotEmpty
                            ? CustomPaint(
                                painter: PlotPolygonPainter(plot.polygon))
                            : Container(color: Colors.grey.shade200))
                  ]),
          ),
        );

        return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
                width: bc.maxWidth < 720 ? bc.maxWidth : 720, child: card));
      }),
    );
  }

  List<Widget> _buildFields(BuildContext context) {
    return [
      Text(plot.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      if (plot.area != null) Text('Area: ${plot.area} ha'),
      if (plot.treeCount != null) Text('Trees: ${plot.treeCount}'),
      if (plot.rowSpacing != null) Text('Row spacing: ${plot.rowSpacing} m'),
      Text(
          'Bed Height: ${plot.bedHeight != null ? '${plot.bedHeight} m' : '-'}'),
    ];
  }

  @override
  double get maxExtent =>
      260; // increased to avoid content overflow on narrow screens

  @override
  double get minExtent => 88;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
