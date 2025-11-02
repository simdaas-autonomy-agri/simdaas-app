import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;
import '../providers/monitoring_providers.dart';
import 'package:simdaas/core/services/auth_service.dart';

class MonitoringScreen extends ConsumerWidget {
  final String? plotId;
  final String? jobId;
  const MonitoringScreen({super.key, this.plotId, this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    final plotsAsync = ref.watch(fm_providers.plotsListProvider(userId));
    final metricsAsync = ref.watch(monitoringStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Data Monitoring')),
      body: plotsAsync.when(
        data: (plots) {
          if (plots.isEmpty)
            return const Center(child: Text('No plots available'));
          final plot = plotId != null
              ? plots.cast<fm_models.PlotModel>().firstWhere(
                  (f) => f.id == plotId,
                  orElse: () => plots.cast<fm_models.PlotModel>().first)
              : plots.cast<fm_models.PlotModel>().first;
          final center = plot.polygon.isNotEmpty
              ? plot.polygon.first
              : LatLng(51.5, -0.09);
          return Stack(children: [
            FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 18.0),
              children: [
                TileLayer(
                    urlTemplate:
                        'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                    subdomains: const ['a', 'b', 'c']),
                if (plot.polygon.isNotEmpty)
                  PolygonLayer(polygons: [
                    Polygon(
                        points: plot.polygon,
                        color: Colors.green.withOpacity(0.15),
                        borderColor: Colors.green,
                        borderStrokeWidth: 2.0)
                  ])
              ],
            ),
            // Overlay: Top card (nozzles + ultrasonics) and bottom controls
            Positioned.fill(
              child: metricsAsync.when(
                data: (metrics) {
                  final m = metrics[plot.id] ?? <String, dynamic>{};

                  String read(dynamic v) => v == null ? '-' : v.toString();

                  final leftNozzle = read(m['leftNozzle'] ?? m['nozzleLeft']);
                  final rightNozzle =
                      read(m['rightNozzle'] ?? m['nozzleRight']);
                  final leftUltra = read(m['leftUltrasonic'] ?? m['ultraLeft']);
                  final rightUltra =
                      read(m['rightUltrasonic'] ?? m['ultraRight']);
                  final coverage =
                      (m['coveragePercent'] ?? m['coverage'] ?? 0).toDouble();
                  final flowRate = read(m['flowRate']);
                  final speed = read(m['tractorSpeed'] ?? m['speed']);
                  final tank = read(m['tankLevel']);
                  final sensorHealth = read(m['sensorHealth']);
                  final ptoOn = (m['ptoState'] ?? m['pto'] ?? false) == true;

                  return Stack(children: [
                    // Top overlay
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: SafeArea(
                        child: Card(
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Row 1: Left nozzle | Right nozzle
                                  Row(children: [
                                    Expanded(
                                        child: _metricBlock(
                                            'Left nozzle', leftNozzle)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _metricBlock(
                                            'Right nozzle', rightNozzle)),
                                  ]),
                                  const SizedBox(height: 8),
                                  // Row 2: Left ultrasonic | Right ultrasonic
                                  Row(children: [
                                    Expanded(
                                        child: _metricBlock(
                                            'Left ultrasonic', leftUltra)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: _metricBlock(
                                            'Right ultrasonic', rightUltra)),
                                  ]),
                                ]),
                          ),
                        ),
                      ),
                    ),

                    // Bottom overlay: progress, summary row, PTO
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: SafeArea(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Card(
                            color: Colors.white.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Progress bar row
                                    Row(children: [
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            const Text('Coverage',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54)),
                                            const SizedBox(height: 6),
                                            LinearProgressIndicator(
                                                value: (coverage.clamp(0, 100) /
                                                    100.0)),
                                            const SizedBox(height: 6),
                                            Text(
                                                '${coverage.toStringAsFixed(1)}% covered',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ])),
                                    ]),
                                    const SizedBox(height: 12),

                                    // summary single-line row
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _smallStat('Flow', flowRate),
                                          _smallStat('Speed', speed),
                                          _smallStat('Tank', tank),
                                          _smallStat('Sensor', sensorHealth),
                                        ]),
                                    const SizedBox(height: 12),

                                    // PTO toggle row
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text('PTO',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 12),
                                          StatefulBuilder(
                                              builder: (ctx, setStateInner) {
                                            var value = ptoOn;
                                            return Switch(
                                              value: value,
                                              onChanged: (v) {
                                                // locally toggle; provider hook may be added later
                                                setStateInner(() => value = v);
                                              },
                                            );
                                          })
                                        ])
                                  ]),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]);
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => Positioned(
                    left: 12,
                    top: 12,
                    child: Card(
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Error: $e')))),
              ),
            )
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading plots: $e')),
      ),
    );
  }
}

Widget _metricBlock(String title, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 6),
      Text(value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]),
  );
}

Widget _smallStat(String label, String value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
