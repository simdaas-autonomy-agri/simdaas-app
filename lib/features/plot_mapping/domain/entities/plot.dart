import 'package:latlong2/latlong.dart';

class PlotEntity {
  final String id;
  final String name;
  // owner/user who created/owns the plot
  final String? userId;
  // total area in hectares
  final double? area;
  // number of trees in the plot
  final int? treeCount;
  // row spacing in meters
  final double? rowSpacing;
  // polygon boundary as list of lat/lng
  final List<LatLng> polygon;
  // centroid of the polygon (computed or stored)
  final LatLng? centroid;
  // bed height in meters
  final double? bedHeight;

  PlotEntity({
    required this.id,
    required this.name,
    this.userId,
    this.area,
    this.treeCount,
    this.rowSpacing,
    required this.polygon,
    this.centroid,
    this.bedHeight,
  });
}
