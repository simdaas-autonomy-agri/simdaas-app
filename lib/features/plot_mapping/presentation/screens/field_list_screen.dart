import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
// removed flutter_map thumbnail; using CustomPaint to draw polygon shapes
import '../providers/plot_providers.dart';
import 'map_screen.dart';

class PlotListScreen extends ConsumerWidget {
  const PlotListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plots')),
        body: const Center(child: Text('Not signed in. Please login.')),
      );
    }

    final plotsAsync = ref.watch(plotsListProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Plots')),
      body: plotsAsync.when(
        data: (plots) => ListView.builder(
          itemCount: plots.length,
          itemBuilder: (context, idx) {
            final f = plots[idx];
            final summary = <String>[];
            if (f.area != null) summary.add('${f.area} ha');
            if (f.rowSpacing != null) summary.add('${f.rowSpacing} m');
            if (f.treeCount != null) summary.add('${f.treeCount} trees');
            if (f.bedHeight != null) summary.add('Bed H: ${f.bedHeight} m');

            return ListTile(
              leading: SizedBox(
                width: 120,
                height: 80,
                child: PlotThumbnail(polygon: f.polygon),
              ),
              title: Text(f.name),
              subtitle: Text(summary.where((s) => s.isNotEmpty).join(' • ')),
              onTap: () {
                showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          title: Text(f.name),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (f.bedHeight != null)
                                Text('Bed Height: ${f.bedHeight} m'),
                              if (f.area != null) Text('Area: ${f.area} ha'),
                              if (f.rowSpacing != null)
                                Text('Row Spacing: ${f.rowSpacing} m'),
                              if (f.treeCount != null)
                                Text('Total Trees: ${f.treeCount}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close')),
                          ],
                        ));
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (c) => const MapScreen()));
        },
        child: const Icon(Icons.add),
      ),
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
      // invert latitude to y coordinate (lat increases northwards)
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
