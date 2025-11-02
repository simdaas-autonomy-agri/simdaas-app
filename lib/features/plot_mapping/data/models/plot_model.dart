import '../../domain/entities/plot.dart';
import 'package:latlong2/latlong.dart';

class PlotModel extends PlotEntity {
  PlotModel({
    required super.id,
    required super.name,
    super.userId,
    super.area,
    super.treeCount,
    super.rowSpacing,
    required super.polygon,
    super.centroid,
    super.bedHeight,
  });

  factory PlotModel.fromJson(String id, Map<String, dynamic> json) {
    final coords = ((json['polygon'] as List<dynamic>?) ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble());
    }).toList();

    LatLng? centroid;
    if (json['centroid'] != null) {
      final c = json['centroid'] as Map<String, dynamic>;
      centroid =
          LatLng((c['lat'] as num).toDouble(), (c['lng'] as num).toDouble());
    } else if (coords.isNotEmpty) {
      // compute simple centroid (average of points)
      final avgLat =
          coords.map((p) => p.latitude).reduce((a, b) => a + b) / coords.length;
      final avgLng = coords.map((p) => p.longitude).reduce((a, b) => a + b) /
          coords.length;
      centroid = LatLng(avgLat, avgLng);
    }

    return PlotModel(
      id: id,
      name: json['name'] as String,
      userId: json['user'].toString() as String? ??
          json['ownerId'].toString() as String?,
      bedHeight: (json['bed_height'] as num?)?.toDouble(),
      polygon: coords,
      area: (json['user_area_acre'] as num?)?.toDouble() ??
          (json['approxArea'] as num?)?.toDouble(),
      rowSpacing: (json['row_spacing'] as num?)?.toDouble(),
      treeCount: (json['tree_count'] as num?)?.toInt(),
      centroid: centroid,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'user': userId,
        'bed_height': bedHeight,
        'user_area_acre': area,
        'row_spacing': rowSpacing,
        'tree_count': treeCount,
        'centroid': centroid == null
            ? null
            : {'lat': centroid!.latitude, 'lng': centroid!.longitude},
        'polygon': polygon
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };
}
