import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../providers/plot_providers.dart';
import 'map_screen.dart';
import 'plot_details_screen.dart';

class PlotListScreen extends ConsumerWidget {
  final bool showFab;
  const PlotListScreen({super.key, this.showFab = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plots')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              const Text('Not signed in. Please login.'),
            ],
          ),
        ),
      );
    }

    final plotsAsync = ref.watch(plotsListProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plots'),
        elevation: 0,
      ),
      body: plotsAsync.when(
        data: (plots) {
          if (plots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No plots yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first plot',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: plots.length,
            itemBuilder: (context, idx) {
              final f = plots[idx];
              final summary = <String>[];
              if (f.area != null) summary.add('${f.area} ha');
              if (f.rowSpacing != null) summary.add('${f.rowSpacing} m');
              if (f.treeCount != null) summary.add('${f.treeCount} trees');
              if (f.bedHeight != null) summary.add('Bed H: ${f.bedHeight} m');

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (c) => PlotDetailsScreen(plot: f)));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 100,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: PlotThumbnail(polygon: f.polygon),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              if (summary.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: summary
                                      .map((s) => Chip(
                                            backgroundColor: Colors.white,
                                            label: Text(
                                              s,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 0,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error: $e'),
            ],
          ),
        ),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool?>(
                    MaterialPageRoute(builder: (c) => const MapScreen()));
                final userId = ref.read(authServiceProvider).currentUserId;
                if (result == true && userId != null) {
                  // Ensure provider is invalidated (MapScreen also invalidates but
                  // we do it here too for immediacy) and show confirmation.
                  ref.invalidate(plotsListProvider(userId));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plot added')));
                }
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Plot'),
            )
          : null,
    );
  }
}

class PlotThumbnail extends StatelessWidget {
  final List<LatLng> polygon;
  const PlotThumbnail({super.key, required this.polygon});

  @override
  Widget build(BuildContext context) {
    if (polygon.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child:
            const Center(child: Icon(Icons.map, size: 28, color: Colors.grey)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
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

    // compute bounds
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

    // add small padding
    final latPad = (maxLat - minLat) * 0.1;
    final lngPad = (maxLng - minLng) * 0.1;
    if (latPad == 0 && lngPad == 0) {
      // single-point fallback
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

    // keep aspect ratio, fit inside
    final scale = math.min(scaleX, scaleY);

    // compute offsets to center the polygon
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
