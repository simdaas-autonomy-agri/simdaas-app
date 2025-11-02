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
    final polygon = plot.polygon.map((p) => [p.latitude, p.longitude]).toList();
    final Map<String, dynamic> payload = {
      'name': plot.name,
      'polygon': polygon,
      'row_spacing': plot.rowSpacing,
      'tree_count': plot.treeCount,
      'user_area_acre': plot.area,
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
      final rawPolygon = jsonItem['polygon'];
      if (rawPolygon is List) {
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
