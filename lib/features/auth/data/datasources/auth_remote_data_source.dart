import 'dart:convert';
import 'package:simdaas/core/services/api_service.dart';
import 'package:simdaas/core/services/api_exception.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<void> logout(String? token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiService api;
  AuthRemoteDataSourceImpl(this.api);

  @override
  Future<UserModel> signIn(String email, String password) async {
    // Postman: POST /api/auth/login/ with { username, password } -> returns { access, refresh }
    final resp = await api.post('/api/auth/login/',
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': email, 'password': password}));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      // user info may not be present; attempt to extract user_id from access token
      String id = '';
      if (data['access'] != null) {
        try {
          final token = data['access'] as String;
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final Map payloadMap = json.decode(decoded) as Map<String, dynamic>;
            if (payloadMap.containsKey('user_id')) {
              id = payloadMap['user_id'].toString();
            }
          }
        } catch (_) {}
      }
      return UserModel(id: id, email: email);
    }
    throw ApiException(resp.statusCode, 'HTTP ${resp.statusCode}',
        path: '/api/auth/login/', body: resp.body);
  }

  @override
  Future<void> logout(String? token) async {
    // Expectation from Postman: POST /api/auth/logout/ with Authorization Bearer <access>
    // and body { refresh_token: "..." }
    if (token == null) return;
    // token here we assume is the access token; logout endpoint may need the refresh token in body
    await api.post('/api/auth/logout/', headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    });
  }
}
