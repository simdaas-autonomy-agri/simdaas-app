import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:simdaas/core/services/api_service.dart';
import 'package:simdaas/core/services/api_exception.dart';
import '../models/job_model.dart';

abstract class JobRemoteDataSource {
  Future<void> createJob(JobModel job);
  Future<List<JobModel>> getJobs(String userId);
  Future<void> updateJob(JobModel job);
}

class JobRemoteDataSourceImpl implements JobRemoteDataSource {
  final ApiService api;
  JobRemoteDataSourceImpl(this.api);

  @override
  Future<void> createJob(JobModel job) async {
    // Backend expects snake_case field names (see Postman collection)
    final j = job.toJson();
    final bodyMap = <String, dynamic>{};
    bodyMap['name'] = j['name'];
    // normalize plot and control unit to primitive ids when possible
    if (j['plot'] != null) bodyMap['plot'] = _extractId(j['plot']);
    if (j['controlUnit'] != null)
      bodyMap['control_unit'] = _extractId(j['controlUnit']);

    // schedule time: ensure ISO string where possible
    if (j['scheduleTime'] != null) {
      final s = j['scheduleTime'];
      if (s is DateTime) {
        bodyMap['schedule_time'] = s.toIso8601String();
      } else {
        bodyMap['schedule_time'] = s;
      }
    }

    if (j['operator'] != null) bodyMap['operator'] = _extractId(j['operator']);

    // spray rate: coerce numeric strings to number
    if (j['sprayRate'] != null) {
      final r = j['sprayRate'];
      if (r is String) {
        bodyMap['spray_rate'] = double.tryParse(r) ?? r;
      } else {
        bodyMap['spray_rate'] = r;
      }
    }

    if (j['productMix'] != null) {
      final pm = j['productMix'];
      // Support our richer mix object from the UI: if the mix is a Map and
      // contains an explicit 'fertilizers' list, send it as an object so the
      // backend can accept inline mix definitions. Otherwise prefer sending
      // the primitive id (existing mix id).
      // NOTE: Dialogs may return an object with an explicit 'mixId' when the
      // user selected an existing mix. In that case prefer sending the
      // existing mix id to the server to avoid creating a duplicate mix.
      if (pm is List && pm.isNotEmpty) {
        final first = pm[0];
        if (first is Map) {
          if (first.containsKey('mixId')) {
            bodyMap['product_mix'] = _extractId(first['mixId']);
          } else if (first.containsKey('fertilizers')) {
            bodyMap['product_mix'] = first;
          } else {
            bodyMap['product_mix'] = _extractId(first);
          }
        } else {
          bodyMap['product_mix'] = _extractId(first);
        }
      } else if (pm is Map) {
        if (pm.containsKey('mixId')) {
          bodyMap['product_mix'] = _extractId(pm['mixId']);
        } else if (pm.containsKey('fertilizers')) {
          bodyMap['product_mix'] = pm;
        } else {
          bodyMap['product_mix'] = _extractId(pm);
        }
      } else {
        bodyMap['product_mix'] = _extractId(pm);
      }
    }

    final body = json.encode(bodyMap);
    // do not log request body in production
    await api.post('/jobs/api/',
        headers: {'Content-Type': 'application/json'}, body: body);
  }

  @override
  Future<List<JobModel>> getJobs(String userId) async {
    final candidates = [
      '/jobs/api/',
    ];
    http.Response? lastResp;
    Exception? lastEx;
    for (final p in candidates) {
      try {
        final resp = await api.get(p);
        lastResp = resp;
        break;
      } catch (e) {
        // capture exception and try next candidate
        lastEx = e as Exception;
      }
    }
    if (lastResp == null) {
      // ignore: avoid_print
      print('JobRemoteDataSource.getJobs failed: $lastEx');
      throw lastEx ?? Exception('Unknown error listing jobs');
    }

    // If the server returned non-JSON (HTML error page), surface it for debugging
    try {
      final data = json.decode(lastResp.body) as List<dynamic>;
      final out = <JobModel>[];
      for (final item in data) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = (map['id']?.toString() ?? map['pk']?.toString() ?? '');
        out.add(JobModel.fromJson(id, map));
      }
      return out;
    } catch (e) {
      // ignore: avoid_print
      print(
          'Failed to parse jobs response (status=${lastResp.statusCode}). Body:\n${lastResp.body}');
      // If we received a non-JSON response from the server, surface a
      // structured ApiException so UI helpers can extract the server body.
      throw ApiException(
          lastResp.statusCode, 'Failed to parse jobs response: ${e.toString()}',
          path: '/jobs/api/', body: lastResp.body);
    }
  }

  @override
  Future<void> updateJob(JobModel job) async {
    if (job.id.isEmpty) throw ArgumentError('Job id required for update');
    final j = job.toJson();
    final bodyMap = <String, dynamic>{};
    if (j.containsKey('name')) bodyMap['name'] = j['name'];
    if (j.containsKey('plot')) bodyMap['plot'] = _extractId(j['plot']);
    if (j.containsKey('controlUnit'))
      bodyMap['control_unit'] = _extractId(j['controlUnit']);
    if (j.containsKey('scheduleTime'))
      bodyMap['schedule_time'] = j['scheduleTime'] is DateTime
          ? (j['scheduleTime'] as DateTime).toIso8601String()
          : j['scheduleTime'];
    if (j.containsKey('operator'))
      bodyMap['operator'] = _extractId(j['operator']);
    if (j.containsKey('sprayRate')) bodyMap['spray_rate'] = j['sprayRate'];
    if (j.containsKey('productMix')) {
      final pm = j['productMix'];
      if (pm is List && pm.isNotEmpty) {
        final first = pm[0];
        if (first is Map) {
          if (first.containsKey('mixId')) {
            bodyMap['product_mix'] = _extractId(first['mixId']);
          } else if (first.containsKey('fertilizers')) {
            bodyMap['product_mix'] = first;
          } else {
            bodyMap['product_mix'] = _extractId(first);
          }
        } else {
          bodyMap['product_mix'] = _extractId(first);
        }
      } else if (pm is Map) {
        if (pm.containsKey('mixId')) {
          bodyMap['product_mix'] = _extractId(pm['mixId']);
        } else if (pm.containsKey('fertilizers')) {
          bodyMap['product_mix'] = pm;
        } else {
          bodyMap['product_mix'] = _extractId(pm);
        }
      } else {
        bodyMap['product_mix'] = _extractId(pm);
      }
    }
    final body = json.encode(bodyMap);
    // prefer PATCH for partial updates, but use POST if server expects it
    await api.post('/jobs/api/${job.id}/',
        headers: {'Content-Type': 'application/json'}, body: body);
  }

  dynamic _extractId(dynamic v) {
    if (v == null) return null;
    if (v is int || v is double) return v;
    if (v is String) {
      final i = int.tryParse(v);
      if (i != null) return i;
      final d = double.tryParse(v);
      if (d != null) return d;
      return v;
    }
    if (v is Map) {
      return _extractId(v['id'] ?? v['pk']);
    }
    return v;
  }
}
