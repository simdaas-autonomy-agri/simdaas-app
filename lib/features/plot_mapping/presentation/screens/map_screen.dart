import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../providers/plot_providers.dart';
import '../providers/map_state_providers.dart';
import '../../data/models/plot_model.dart';
import 'package:simdaas/core/services/auth_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  final LatLng? initialCenter;
  const MapScreen({super.key, this.initialCenter});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  Offset? _lastPointerPosition;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // (multi-pointer centroid removed; we use simple single-touch drag for vertices)
  double _computeAreaHa(List<LatLng> poly) {
    if (poly.length < 3) return 0.0;
    const R = 6371000.0; // Earth radius in meters
    // use centroid latitude for projection scale
    double sumLat = 0;
    for (final p in poly) sumLat += p.latitude;
    final lat0 = (sumLat / poly.length) * (math.pi / 180.0);

    List<double> xs = [];
    List<double> ys = [];
    for (final p in poly) {
      final latRad = p.latitude * (math.pi / 180.0);
      final lonRad = p.longitude * (math.pi / 180.0);
      final x = R * lonRad * math.cos(lat0);
      final y = R * latRad;
      xs.add(x);
      ys.add(y);
    }

    double area = 0.0;
    for (int i = 0; i < xs.length; i++) {
      final j = (i + 1) % xs.length;
      area += xs[i] * ys[j] - xs[j] * ys[i];
    }
    area = area.abs() * 0.5; // in square meters
    return area / 10000.0; // hectares
  }

  void _onTapTap(TapPosition tapPos, LatLng latlng) {
    final mapNotifier = ref.read(mapStateProvider.notifier);
    final currentPoints = ref.read(mapStateProvider).points;

    // try to insert on nearest segment if close
    final idx = _nearestSegmentIndex(latlng, currentPoints);
    if (idx != null) {
      mapNotifier.insertPoint(idx + 1, latlng);
      // normalize and select the newly inserted point
      final moved = latlng;
      final updatedPoints = ref.read(mapStateProvider).points;
      final normalized = _normalizePolygon(updatedPoints);
      mapNotifier.setPoints(normalized);
      mapNotifier.selectVertex(_findNearestIndex(moved, normalized));
      return;
    }

    // otherwise append
    mapNotifier.addPoint(latlng);
    // normalize and select appended
    final moved = latlng;
    final updatedPoints = ref.read(mapStateProvider).points;
    final normalized = _normalizePolygon(updatedPoints);
    mapNotifier.setPoints(normalized);
    mapNotifier.selectVertex(_findNearestIndex(moved, normalized));
  }

  // compute nearest segment index to a point; returns index i for segment between points[i] and points[i+1]
  int? _nearestSegmentIndex(LatLng p, List<LatLng> points) {
    if (points.length < 2) return null;
    // use centroid latitude for projection
    double sumLat = 0;
    for (final pt in points) sumLat += pt.latitude;
    final lat0 = (sumLat / points.length) * (math.pi / 180.0);
    const R = 6371000.0;

    double px = R * (p.longitude * (math.pi / 180.0)) * math.cos(lat0);
    double py = R * (p.latitude * (math.pi / 180.0));

    double bestDist = double.infinity;
    int? bestIdx;
    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final ax = R * (a.longitude * (math.pi / 180.0)) * math.cos(lat0);
      final ay = R * (a.latitude * (math.pi / 180.0));
      final bx = R * (b.longitude * (math.pi / 180.0)) * math.cos(lat0);
      final by = R * (b.latitude * (math.pi / 180.0));

      final vx = bx - ax;
      final vy = by - ay;
      final wx = px - ax;
      final wy = py - ay;
      final c1 = vx * wx + vy * wy;
      final c2 = vx * vx + vy * vy;
      double t = 0.0;
      if (c2 > 0) t = (c1 / c2).clamp(0.0, 1.0);
      final projx = ax + t * vx;
      final projy = ay + t * vy;
      final dx = px - projx;
      final dy = py - projy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }

    // threshold: 20 meters
    if (bestDist.isFinite && bestDist <= 20.0) return bestIdx;
    return null;
  }

  @override
  void initState() {
    super.initState();
    // move the map after first frame if an initial center was provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = widget.initialCenter;
      if (c != null) {
        _mapController.move(c, 18.0);
      }
    });

    // listen to search text changes for autocomplete
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final searchNotifier = ref.read(searchStateProvider.notifier);
    final text = _searchCtrl.text.trim();
    if (text.isEmpty) {
      searchNotifier.clearSuggestions();
      return;
    }

    // skip if it's lat,lng format
    if (text.contains(',')) {
      searchNotifier.clearSuggestions();
      return;
    }

    searchNotifier.setSearching(true);

    // debounce: wait a bit before searching
    await Future.delayed(const Duration(milliseconds: 500));
    if (_searchCtrl.text.trim() != text) return; // user kept typing

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(text)}&format=json&limit=5');
      final resp =
          await http.get(url, headers: {'User-Agent': 'SmartSprayerApp/1.0'});
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body) as List;
        if (mounted) {
          searchNotifier.setSuggestions(data.cast<Map<String, dynamic>>());
        }
      } else {
        if (mounted) {
          searchNotifier.clearSuggestions();
        }
      }
    } catch (_) {
      if (mounted) {
        searchNotifier.clearSuggestions();
      }
    }
  }

  void _navigateToLocation(String text) async {
    if (text.isEmpty) return;
    LatLng? center;
    if (text.contains(',')) {
      final parts = text.split(',');
      try {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        center = LatLng(lat, lng);
      } catch (_) {}
    } else {
      // geocode via Nominatim
      try {
        final url = Uri.parse(
            'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(text)}&format=json&limit=1');
        final resp =
            await http.get(url, headers: {'User-Agent': 'SmartSprayerApp/1.0'});
        if (resp.statusCode == 200) {
          final List data = json.decode(resp.body) as List;
          if (data.isNotEmpty) {
            final first = data.first as Map<String, dynamic>;
            final lat = double.parse(first['lat'] as String);
            final lon = double.parse(first['lon'] as String);
            center = LatLng(lat, lon);
          }
        }
      } catch (_) {}
    }

    if (center != null) {
      _mapController.move(center, 18.0);
      ref.read(searchStateProvider.notifier).clearSuggestions();
      _searchFocus.unfocus();
    }
  }

  Future<void> _saveField() async {
    final mapState = ref.read(mapStateProvider);
    final points = mapState.points;

    final nameCtrl = TextEditingController();
    final zipCtrl = TextEditingController();
    final bedHeightCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final rowSpacingCtrl = TextEditingController();
    final obstaclesCtrl = TextEditingController();
    final treeCountCtrl = TextEditingController();
    // prefill area suggestion
    try {
      final suggested = _computeAreaHa(points);
      if (suggested > 0) areaCtrl.text = suggested.toStringAsFixed(2);
    } catch (_) {}
    final res = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Plot Name')),
          TextField(
              controller: zipCtrl,
              decoration: const InputDecoration(labelText: 'Pin / Zip Code')),
          TextField(
              controller: bedHeightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bed Height (m)')),
          TextField(
              controller: areaCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Approx Area (ha)')),
          TextField(
              controller: rowSpacingCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Row Spacing (m)')),
          TextField(
              controller: obstaclesCtrl,
              decoration:
                  const InputDecoration(labelText: 'Obstacles (notes)')),
          TextField(
              controller: treeCountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Trees')),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'))
        ]),
      ),
    );
    if (res == true) {
      final owner = ref.read(authServiceProvider).currentUserId;
      double? approx;
      try {
        approx = double.parse(areaCtrl.text);
      } catch (_) {
        approx = null;
      }
      double? rowSpacing;
      try {
        rowSpacing = double.parse(rowSpacingCtrl.text);
      } catch (_) {
        rowSpacing = null;
      }
      // note: obstacles input is collected but not stored in the canonical PlotModel
      int? treeCount;
      try {
        treeCount = int.parse(treeCountCtrl.text);
      } catch (_) {
        treeCount = null;
      }
      // normalize polygon before saving
      final normalizedPoints = _normalizePolygon(points);
      ref.read(mapStateProvider.notifier).setPoints(normalizedPoints);

      // map legacy form fields into the new PlotModel fields
      final model = PlotModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameCtrl.text,
          bedHeight: (bedHeightCtrl.text.isEmpty)
              ? null
              : double.tryParse(bedHeightCtrl.text),
          area: approx,
          rowSpacing: rowSpacing,
          treeCount: treeCount,
          polygon: normalizedPoints,
          userId: owner);
      final repo = ref.read(plotRepoProvider);
      await repo.addPlot(model);
      if (!mounted) return;
      // Invalidate plots list so screens watching it refresh automatically
      final currentUserId =
          ref.read(authServiceProvider).currentUserId ?? 'demo_user';
      ref.invalidate(plotsListProvider(currentUserId));
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final searchState = ref.watch(searchStateProvider);
    final points = mapState.points;
    final selectedVertex = mapState.selectedVertex;
    final absorbMap = mapState.absorbMap;
    final searchSuggestions = searchState.suggestions;
    final isSearching = searchState.isSearching;

    return Scaffold(
      appBar: AppBar(title: const Text('Map Plot')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onTap: _onTapTap,
              initialZoom: 18.0,
              // Disable map interactions when dragging a vertex
              interactionOptions: InteractionOptions(
                flags: absorbMap ? InteractiveFlag.none : InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                  urlTemplate:
                      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                  subdomains: const ['a', 'b', 'c']),
              if (points.isNotEmpty) ...[
                PolygonLayer(polygons: [
                  Polygon(
                      points: points,
                      color: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 3.0,
                      borderColor: Colors.blue)
                ]),
                MarkerLayer(
                  markers: List.generate(points.length, (i) {
                    final p = points[i];
                    return Marker(
                      point: p,
                      width: 44,
                      height: 44,
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) {
                          // Select vertex and disable map interactions
                          final mapNotifier =
                              ref.read(mapStateProvider.notifier);
                          mapNotifier.selectVertex(i);
                          mapNotifier.setAbsorbMap(true);
                          _lastPointerPosition = event.position;
                        },
                        onPointerMove: (event) {
                          if (selectedVertex != i ||
                              _lastPointerPosition == null) return;

                          try {
                            // Get the map's camera
                            final camera = _mapController.camera;

                            // Get the render box to convert global position to local
                            final RenderBox? box =
                                context.findRenderObject() as RenderBox?;
                            if (box == null) return;

                            // Convert global positions to local widget positions
                            final lastLocal =
                                box.globalToLocal(_lastPointerPosition!);
                            final currentLocal =
                                box.globalToLocal(event.position);

                            // Use camera's method to convert screen point to LatLng
                            // The camera.pointToLatLng expects a point relative to the map
                            final lastLatLng = camera.offsetToCrs(
                                Offset(lastLocal.dx, lastLocal.dy));
                            final currentLatLng = camera.offsetToCrs(
                                Offset(currentLocal.dx, currentLocal.dy));

                            // Calculate the delta in lat/lng space
                            final deltaLat =
                                currentLatLng.latitude - lastLatLng.latitude;
                            final deltaLng =
                                currentLatLng.longitude - lastLatLng.longitude;

                            // Apply the delta to the vertex position
                            final currentVertex = points[i];
                            final newLat = currentVertex.latitude + deltaLat;
                            final newLng = currentVertex.longitude + deltaLng;

                            final mapNotifier =
                                ref.read(mapStateProvider.notifier);
                            if (selectedVertex != null &&
                                selectedVertex < points.length) {
                              mapNotifier.updatePoint(
                                  selectedVertex, LatLng(newLat, newLng));
                            }
                            _lastPointerPosition = event.position;
                          } catch (e) {
                            // If anything fails, just update the last position
                            _lastPointerPosition = event.position;
                          }
                        },
                        onPointerUp: (event) {
                          final mapNotifier =
                              ref.read(mapStateProvider.notifier);
                          mapNotifier.setAbsorbMap(false);
                          _lastPointerPosition = null;
                        },
                        onPointerCancel: (event) {
                          final mapNotifier =
                              ref.read(mapStateProvider.notifier);
                          mapNotifier.setAbsorbMap(false);
                          _lastPointerPosition = null;
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                selectedVertex == i ? Colors.red : Colors.white,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ]
            ],
          ),
          // ...existing code...
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          decoration: const InputDecoration(
                            hintText: 'Search location or lat,lng',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (text) {
                            _navigateToLocation(text.trim());
                          },
                        ),
                      ),
                      if (isSearching)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () {
                            _navigateToLocation(_searchCtrl.text.trim());
                          },
                          icon: const Icon(Icons.search),
                        ),
                    ]),
                  ),
                ),
                if (searchSuggestions.isNotEmpty)
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(top: 4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = searchSuggestions[index];
                        final displayName =
                            suggestion['display_name'] as String;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(
                            displayName,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            final lat =
                                double.parse(suggestion['lat'] as String);
                            final lon =
                                double.parse(suggestion['lon'] as String);
                            _mapController.move(LatLng(lat, lon), 18.0);
                            _searchCtrl.text = displayName;
                            ref
                                .read(searchStateProvider.notifier)
                                .clearSuggestions();
                            _searchFocus.unfocus();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // controls for selected vertex
          if (selectedVertex != null)
            Positioned(
              bottom: 80,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(children: [
                    TextButton.icon(
                      onPressed: () {
                        final mapNotifier = ref.read(mapStateProvider.notifier);
                        final currentState = ref.read(mapStateProvider);
                        if (currentState.selectedVertex != null &&
                            currentState.selectedVertex! < points.length) {
                          final removed = points[currentState.selectedVertex!];
                          mapNotifier.deletePoint(currentState.selectedVertex!);
                          // normalize and restore selection to nearest
                          final currentPoints =
                              ref.read(mapStateProvider).points;
                          final normalized = _normalizePolygon(currentPoints);
                          mapNotifier.setPoints(normalized);
                          final nearestIdx =
                              _findNearestIndex(removed, normalized);
                          mapNotifier.selectVertex(nearestIdx);
                        }
                        mapNotifier.clearSelection();
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete'),
                    ),
                    const SizedBox(width: 8),
                    // removed move button: vertices are draggable directly
                  ]),
                ),
              ),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveField,
        child: const Icon(Icons.save),
      ),
    );
  }

  // Normalize polygon vertices by sorting points by angle around centroid.
  List<LatLng> _normalizePolygon(List<LatLng> pts) {
    if (pts.length < 3) return List<LatLng>.from(pts);
    double cx = 0, cy = 0;
    for (final p in pts) {
      cx += p.latitude;
      cy += p.longitude;
    }
    cx /= pts.length;
    cy /= pts.length;
    final center = LatLng(cx, cy);
    final withAngles = <MapEntry<double, LatLng>>[];
    for (final p in pts) {
      final angle = math.atan2(
          p.latitude - center.latitude, p.longitude - center.longitude);
      withAngles.add(MapEntry(angle, p));
    }
    withAngles.sort((a, b) => a.key.compareTo(b.key));
    return withAngles.map((e) => e.value).toList();
  }

  int? _findNearestIndex(LatLng target, List<LatLng> pts) {
    if (pts.isEmpty) return null;
    double bestDist = double.infinity;
    int bestIdx = 0;
    for (int i = 0; i < pts.length; i++) {
      final dLat = pts[i].latitude - target.latitude;
      final dLng = pts[i].longitude - target.longitude;
      final dist = dLat * dLat + dLng * dLng;
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }
    return bestIdx;
  }
}
