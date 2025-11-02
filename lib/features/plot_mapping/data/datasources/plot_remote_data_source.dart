import 'dart:convert';
import 'package:simdaas/core/services/api_service.dart';
import '../models/plot_model.dart';

abstract class PlotRemoteDataSource {
  Future<void> addPlot(PlotModel plot);
  Future<List<PlotModel>> getPlots(String userId);
}

class PlotRemoteDataSourceImpl implements PlotRemoteDataSource {
  final ApiService api;
  PlotRemoteDataSourceImpl(this.api);

  @override
  Future<void> addPlot(PlotModel plot) async {
    // Build payload matching backend expectations.
    // Example body:
    // {
    //   "name": "knpur nankari",
    //   "polygon": [[lat,lng],[...]],
    //   "row_spacing": 2.5,
    //   "tree_count": 100,
    //   "user_area_acre": 1.5,
    //   "bed_height": "145"
    // }
    final polygon = plot.polygon.map((p) => [p.latitude, p.longitude]).toList();
    final Map<String, dynamic> payload = {
      'name': plot.name,
      'polygon': polygon,
      'row_spacing': plot.rowSpacing,
      'tree_count': plot.treeCount,
      'user_area_acre': plot.area,
      // backend sample used a string for bed_height; convert to string if present
      'bed_height': plot.bedHeight != null ? plot.bedHeight.toString() : null,
    };
    final body = json.encode(payload);
    await api.post('/plot/api/',
        headers: {'Content-Type': 'application/json'}, body: body);
  }

  @override
  Future<List<PlotModel>> getPlots(String userId) async {
    final resp = await api.get('/plot/api/');
    final data = json.decode(resp.body) as List<dynamic>;
    final List<PlotModel> out = [];
    for (final item in data) {
      final Map<String, dynamic> jsonItem = item as Map<String, dynamic>;
      // Backend may provide polygon as [[lat,lng],...] or as [{lat,lng},...]
      final rawPolygon = jsonItem['polygon'];
      if (rawPolygon is List) {
        // normalize to list of maps with 'lat' and 'lng' for PlotModel.fromJson
        final poly = rawPolygon
            .map((e) {
              if (e is List && e.length >= 2) return {'lat': e[0], 'lng': e[1]};
              if (e is Map) return {'lat': e['lat'], 'lng': e['lng']};
              return null;
            })
            .where((e) => e != null)
            .toList();
        jsonItem['polygon'] = poly;
      }
      final id =
          (jsonItem['id']?.toString() ?? jsonItem['pk']?.toString() ?? '');
      out.add(PlotModel.fromJson(id, jsonItem));
    }
    return out;
  }
}
