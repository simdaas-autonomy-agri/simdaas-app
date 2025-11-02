import 'dart:convert';

import 'package:simdaas/core/services/api_service.dart';

class FertilizersRemoteDataSource {
  final ApiService api;
  FertilizersRemoteDataSource(this.api);

  Future<List<Map<String, dynamic>>> getFertilizers() async {
    final resp = await api.get('/fertilizers/api/');
    final decoded = json.decode(resp.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getFertilizerMixes() async {
    final resp = await api.get('/fertilizers/api-mixes/');
    final decoded = json.decode(resp.body) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createMix(Map<String, dynamic> payload) async {
    final resp = await api.post('/fertilizers/api-mixes/',
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload));
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createFertilizer(
      Map<String, dynamic> payload) async {
    final resp = await api.post('/fertilizers/api/',
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload));
    return json.decode(resp.body) as Map<String, dynamic>;
  }
}
