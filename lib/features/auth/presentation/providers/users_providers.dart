import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/api_service.dart';
import 'package:simdaas/core/services/auth_service.dart';

// NOTE: This file was originally Firestore-backed. It now uses the REST API
// via `ApiService` (provided by `apiServiceProvider`). The providers return
// plain Maps containing an `id` key so existing UI that expects either
// QueryDocumentSnapshot or Map will continue to work.

/// Simple users controller that exposes listing and creation helpers using REST.
class UsersController {
  final Ref ref;
  UsersController(this.ref);

  ApiService get _api => ref.read(apiServiceProvider);

  /// Returns a list of user maps. Each map contains an `id` key.
  Future<List<Map<String, dynamic>>> listUsers() async {
    try {
      final candidates = [
        '/api/users/',
        '/api/users',
        '/users/api/',
        '/users/api',
        '/users/',
        '/users'
      ];
      http.Response? lastResp;
      Exception? lastEx;
      for (final p in candidates) {
        try {
          final resp = await _api.get(p);
          lastResp = resp;
          break;
        } catch (e) {
          lastEx = e as Exception;
          // try next
        }
      }
      if (lastResp == null) {
        // ignore: avoid_print
        print('UsersController.listUsers error: $lastEx');
        throw lastEx ?? Exception('Unknown error');
      }
      if (lastResp.statusCode != 200) return [];
      final arr = json.decode(lastResp.body) as List<dynamic>;
      final out = <Map<String, dynamic>>[];
      for (final item in arr) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = (map['id']?.toString() ?? map['pk']?.toString() ?? '');
        map['id'] = id;
        out.add(map);
      }
      // no debug logging
      return out;
    } catch (e, st) {
      // Log and surface error to callers
      // ignore: avoid_print
      print('UsersController.listUsers error: $e\n$st');
      rethrow;
    }
  }

  /// Create a new user via the REST API. Returns the created user's id if
  /// available.
  Future<String> createUser(
      {required String email,
      required String password,
      required String name,
      String? phone,
      List<String>? roles}) async {
    final body = json.encode({
      'email': email,
      'password': password,
      'name': name,
      'phone': phone ?? '',
      'roles': roles ?? ['operator']
    });
    final candidates = [
      '/api/users/',
      '/api/users',
      '/users/api/',
      '/users/api',
      '/users/',
      '/users'
    ];
    http.Response? lastResp;
    Exception? lastEx;
    for (final p in candidates) {
      try {
        final resp = await _api.post(p,
            headers: {'Content-Type': 'application/json'}, body: body);
        lastResp = resp;
        break;
      } catch (e) {
        lastEx = e as Exception;
      }
    }
    if (lastResp != null &&
        (lastResp.statusCode == 200 || lastResp.statusCode == 201)) {
      final data = json.decode(lastResp.body) as Map<String, dynamic>;
      final id = (data['id']?.toString() ?? data['pk']?.toString() ?? '');
      ref.invalidate(usersListProvider);
      return id;
    }
    ref.invalidate(usersListProvider);
    throw Exception(
        'Create user failed: ${lastResp?.statusCode} ${lastResp?.body} ${lastEx ?? ''}');
  }
}

final usersControllerProvider = Provider((ref) => UsersController(ref));

/// Operators collection (simple list + create helper) via REST.
class OperatorsController {
  final Ref ref;
  OperatorsController(this.ref);

  ApiService get _api => ref.read(apiServiceProvider);

  Future<List<Map<String, dynamic>>> listOperators() async {
    try {
      final candidates = [
        '/api/operators/',
        '/api/operators',
        '/operators/api/',
        '/operators/api',
        '/operators/',
        '/operators'
      ];
      http.Response? lastResp;
      Exception? lastEx;
      for (final p in candidates) {
        try {
          final resp = await _api.get(p);
          lastResp = resp;
          break;
        } catch (e) {
          lastEx = e as Exception;
        }
      }
      if (lastResp == null) {
        // ignore: avoid_print
        print('OperatorsController.listOperators error: $lastEx');
        throw lastEx ?? Exception('Unknown error');
      }
      if (lastResp.statusCode != 200) return [];
      final arr = json.decode(lastResp.body) as List<dynamic>;
      final out = <Map<String, dynamic>>[];
      for (final item in arr) {
        final map = Map<String, dynamic>.from(item as Map);
        // normalize snake_case -> camelCase for UI
        if (map.containsKey('contact_number'))
          map['phone'] = map['contact_number'];
        if (map.containsKey('experience_years'))
          map['experienceYears'] = map['experience_years'];
        final id = (map['id']?.toString() ?? map['pk']?.toString() ?? '');
        map['id'] = id;
        out.add(map);
      }
      return out;
    } catch (e, st) {
      // Log and rethrow; callers (providers) will show errors
      // ignore: avoid_print
      print('OperatorsController.listOperators error: $e\n$st');
      rethrow;
    }
  }

  /// Create an operator. Accepts the full set of fields the backend
  /// expects (snake_case keys are constructed here).
  Future<String> createOperator({
    required String name,
    String? contactNumber,
    String? email,
    String? address,
    int? experienceYears,
    String? assignedMachine,
    String? shiftTiming,
    bool? isActive,
  }) async {
    final bodyMap = <String, dynamic>{
      'name': name,
      'contact_number': contactNumber ?? '',
      'email': email ?? '',
      'address': address ?? '',
      'experience_years': experienceYears ?? 0,
      'assigned_machine': assignedMachine ?? '',
      'shift_timing': shiftTiming ?? '',
      'is_active': isActive ?? true,
    };

    final body = json.encode(bodyMap);

    final candidates = [
      '/api/operators/',
      '/api/operators',
      '/operators/api/',
      '/operators/api',
      '/operators/',
      '/operators'
    ];
    http.Response? lastResp;
    Exception? lastEx;
    for (final p in candidates) {
      try {
        final resp = await _api.post(p,
            headers: {'Content-Type': 'application/json'}, body: body);
        lastResp = resp;
        break;
      } catch (e) {
        lastEx = e as Exception;
      }
    }
    if (lastResp != null &&
        (lastResp.statusCode == 200 || lastResp.statusCode == 201)) {
      final data = json.decode(lastResp.body) as Map<String, dynamic>;
      final id = (data['id']?.toString() ?? data['pk']?.toString() ?? '');
      ref.invalidate(operatorsListProvider);
      return id;
    }
    ref.invalidate(operatorsListProvider);
    throw Exception(
        'Create operator failed: ${lastResp?.statusCode} ${lastResp?.body} ${lastEx ?? ''}');
  }
}

final operatorsControllerProvider = Provider((ref) => OperatorsController(ref));

final operatorsListProvider = FutureProvider((ref) async {
  final ctrl = ref.read(operatorsControllerProvider);
  final ops = await ctrl.listOperators();
  return ops;
});

// Users list provider: return an empty list on error so screens that display
// jobs (which also try to resolve user names) don't fail when the users
// endpoint is unavailable. The controller still exposes errors to callers
// that want to surface them explicitly.
final usersListProvider = FutureProvider((ref) async {
  final ctrl = ref.read(usersControllerProvider);
  try {
    final users = await ctrl.listUsers();
    return users;
  } catch (e, st) {
    // ignore: avoid_print
    print('usersListProvider: failed to load users: $e\n$st');
    return <Map<String, dynamic>>[];
  }
});
