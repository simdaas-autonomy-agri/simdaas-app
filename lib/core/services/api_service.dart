import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  ApiService({required this.baseUrl, this.client});

  final String baseUrl;
  final http.Client? client;
  String? _authToken;

  // Callback to refresh token when 401 occurs
  Future<String?> Function()? onTokenExpired;

  /// Expose current auth token for debugging (do not use in production UI).
  String? get authToken => _authToken;

  /// Set the current access token (Bearer). Passing null clears the token.
  void setAuthToken(String? token) {
    _authToken = token;
    debugPrint(
        'ApiService.setAuthToken: token set to ${token != null ? '${token.substring(0, 8)}...' : 'null'}');
  }

  Uri url(String path) => Uri.parse(baseUrl + path);

  Future<http.Response> get(String path,
      {Map<String, String>? headers, bool requiresAuth = true}) async {
    try {
      final c = client ?? http.Client();
      final h = requiresAuth ? _withAuth(headers) : (headers ?? {});
      debugPrint(
          'ApiService.GET $path with auth: ${h.containsKey('Authorization')}');
      final resp = await c.get(url(path), headers: h);
      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      // If 401 and we have a refresh callback, try to refresh and retry
      // Only attempt refresh if this request requires auth
      if (resp.statusCode == 401 && requiresAuth && onTokenExpired != null) {
        debugPrint(
            'ApiService.GET $path: Got 401, attempting token refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null) {
          debugPrint('ApiService.GET $path: Token refreshed, retrying request');
          final h2 = _withAuth(headers);
          final resp2 = await c.get(url(path), headers: h2);
          _ensureSuccess(resp2, path);
          return resp2;
        }
      }

      _ensureSuccess(resp, path);
      debugPrint(
          "GET request to $path succeeded. Response: ${resp.body.length} bytes");
      return resp;
    } catch (e) {
      debugPrint('ApiService.GET $path error: $e');
      throw ApiException(null, 'Network error: $e', path: path);
    }
  }

  Future<http.Response> post(String path,
      {Map<String, String>? headers,
      Object? body,
      bool requiresAuth = true}) async {
    try {
      final c = client ?? http.Client();
      final h = requiresAuth ? _withAuth(headers) : (headers ?? {});
      debugPrint(
          'ApiService.POST $path with auth: ${h.containsKey('Authorization')}');
      final resp = await c.post(url(path), headers: h, body: body);

      // If 401 and we have a refresh callback, try to refresh and retry
      // Only attempt refresh if this request requires auth
      if (resp.statusCode == 401 && requiresAuth && onTokenExpired != null) {
        debugPrint(
            'ApiService.POST $path: Got 401, attempting token refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null) {
          debugPrint(
              'ApiService.POST $path: Token refreshed, retrying request');
          final h2 = _withAuth(headers);
          final resp2 = await c.post(url(path), headers: h2, body: body);
          _ensureSuccess(resp2, path);
          return resp2;
        }
      }

      _ensureSuccess(resp, path);
      return resp;
    } catch (e) {
      debugPrint('ApiService.POST $path error: $e');
      throw ApiException(null, 'Network error: $e', path: path);
    }
  }

  Future<http.Response> put(String path,
      {Map<String, String>? headers, Object? body}) async {
    try {
      final c = client ?? http.Client();
      final h = _withAuth(headers);
      final resp = await c.put(url(path), headers: h, body: body);
      _ensureSuccess(resp, path);
      return resp;
    } catch (e) {
      throw ApiException(null, 'Network error: $e', path: path);
    }
  }

  Future<http.Response> delete(String path,
      {Map<String, String>? headers}) async {
    try {
      final c = client ?? http.Client();
      final h = _withAuth(headers);
      final resp = await c.delete(url(path), headers: h);
      _ensureSuccess(resp, path);
      return resp;
    } catch (e) {
      throw ApiException(null, 'Network error: $e', path: path);
    }
  }

  void _ensureSuccess(http.Response resp, String path) {
    final code = resp.statusCode;
    if (code < 200 || code >= 300) {
      throw ApiException(code, 'HTTP ${resp.statusCode}',
          path: path, body: resp.body);
    }
  }

  Map<String, String> _withAuth(Map<String, String>? headers) {
    final result = <String, String>{};
    if (headers != null) result.addAll(headers);
    if (_authToken != null && _authToken!.isNotEmpty) {
      result['Authorization'] = 'Bearer $_authToken';
    }
    return result;
  }
}
