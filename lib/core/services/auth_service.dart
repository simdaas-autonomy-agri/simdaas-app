import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Create a single ApiService instance that will be shared across the app
final _apiServiceInstance = ApiService(baseUrl: apiBaseUrl);

final apiServiceProvider = Provider<ApiService>((ref) {
  return _apiServiceInstance;
});

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  final svc = AuthService(_apiServiceInstance);
  // Register token refresh callback
  _apiServiceInstance.onTokenExpired = () async {
    debugPrint('AuthService: Token expired callback triggered');
    final refreshed = await svc.refreshAccessToken();
    if (refreshed) {
      debugPrint('AuthService: Token successfully refreshed');
      return svc.token;
    }
    debugPrint('AuthService: Token refresh failed, clearing local credentials');
    await svc.handleRefreshFailure();
    return null;
  };
  // attempt to load persisted tokens
  svc._loadFromStorage();
  return svc;
});

class AuthService extends ChangeNotifier {
  AuthService(this._api);

  final ApiService _api;
  final _storage = const FlutterSecureStorage();

  String? _token;
  String? _refreshToken;
  String? _userId;
  bool _isRefreshing = false;

  String? get token => _token;
  String? get currentUserId => _userId;

  Future<bool> signIn(String username, String password) async {
    // Postman collection: POST {{baseUrl}}/api/auth/login/ -> returns { access, refresh }
    // IMPORTANT: requiresAuth = false - you can't be authenticated before logging in!
    final resp = await _api.post('/api/auth/login/',
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
        requiresAuth: false);
    // Debug: log response for troubleshooting
    debugPrint('AuthService.signIn -> status: ${resp.statusCode}');
    debugPrint('AuthService.signIn -> body: ${resp.body}');

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final Map data = json.decode(resp.body) as Map<String, dynamic>;
      _token = data['access'] as String?;
      _refreshToken = data['refresh'] as String?;
      // persist tokens
      try {
        if (_token != null) {
          await _storage.write(key: 'access_token', value: _token);
          debugPrint('AuthService: wrote access_token to storage');
        }
        if (_refreshToken != null) {
          await _storage.write(key: 'refresh_token', value: _refreshToken);
          debugPrint('AuthService: wrote refresh_token to storage');
        }
      } catch (e) {
        debugPrint('AuthService: failed writing tokens to storage: $e');
      }
      // inform ApiService of auth token
      _api.setAuthToken(_token);
      debugPrint(
          'AuthService.signIn: Set token on ApiService, token starts with: ${_token!.substring(0, 20)}...');
      // extract user id from JWT payload if present
      if (_token != null) {
        try {
          final parts = _token!.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final Map payloadMap = json.decode(decoded) as Map<String, dynamic>;
            if (payloadMap.containsKey('user_id')) {
              _userId = payloadMap['user_id'].toString();
            }
          }
        } catch (_) {
          // ignore decode errors
        }
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    // call backend logout if needed
    if (_token != null || _refreshToken != null) {
      try {
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (_token != null) {
          headers['Authorization'] = 'Bearer $_token';
        }
        final body = json.encode({'refresh_token': _refreshToken});
        // Postman collection: POST {{baseUrl}}/api/auth/logout/ with body { refresh_token }
        await _api.post('/api/auth/logout/', headers: headers, body: body);
      } catch (_) {}
    }
    _token = null;
    _refreshToken = null;
    _userId = null;
    // clear persisted tokens and ApiService
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    } catch (_) {}
    _api.setAuthToken(null);
    notifyListeners();
  }

  // Load tokens from secure storage into memory and set ApiService token
  Future<void> _loadFromStorage() async {
    try {
      final a = await _storage.read(key: 'access_token');
      final r = await _storage.read(key: 'refresh_token');
      debugPrint(
          'AuthService._loadFromStorage -> access: ${a == null ? 'null' : (a.length > 8 ? a.substring(0, 8) + '...' : a)}');
      debugPrint(
          'AuthService._loadFromStorage -> refresh: ${r == null ? 'null' : (r.length > 8 ? r.substring(0, 8) + '...' : r)}');
      if (a != null) {
        _token = a;
        _api.setAuthToken(_token);
        debugPrint('AuthService._loadFromStorage: Token set on ApiService');

        // Check if token is expired by decoding JWT
        bool isExpired = false;
        try {
          final parts = _token!.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final Map payloadMap = json.decode(decoded) as Map<String, dynamic>;

            // Extract user_id
            if (payloadMap.containsKey('user_id')) {
              _userId = payloadMap['user_id'].toString();
            }

            // Check expiration
            if (payloadMap.containsKey('exp')) {
              final exp = payloadMap['exp'] as int;
              final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
              final now = DateTime.now();
              isExpired = now.isAfter(expDate);
              debugPrint(
                  'AuthService._loadFromStorage: Token expires at $expDate, current time $now, expired: $isExpired');
            }
          }
        } catch (e) {
          debugPrint('AuthService._loadFromStorage: Error parsing token: $e');
        }

        // If token is expired, try to refresh it
        if (isExpired && r != null) {
          debugPrint(
              'AuthService._loadFromStorage: Token is expired, attempting refresh...');
          _refreshToken = r;
          final refreshed = await refreshAccessToken();
          if (!refreshed) {
            debugPrint(
                'AuthService._loadFromStorage: Refresh failed, clearing tokens');
            _token = null;
            _refreshToken = null;
            _userId = null;
            _api.setAuthToken(null);
            await _storage.delete(key: 'access_token');
            await _storage.delete(key: 'refresh_token');
          }
        }
      }
      if (r != null) _refreshToken = r;
      // notify listeners after loading persisted tokens
      notifyListeners();
    } catch (_) {}
  }

  /// Refresh the access token using refresh token stored in memory or secure storage.
  /// Returns true if refresh succeeded and tokens were updated.
  Future<bool> refreshAccessToken() async {
    // Avoid concurrent refresh attempts
    if (_isRefreshing) {
      debugPrint(
          'AuthService.refreshAccessToken: Already refreshing, aborting concurrent attempt');
      return false;
    }
    _isRefreshing = true;
    debugPrint('AuthService.refreshAccessToken: Starting token refresh...');
    try {
      var refresh = _refreshToken;
      if (refresh == null) {
        refresh = await _storage.read(key: 'refresh_token');
        if (refresh == null) {
          debugPrint(
              'AuthService.refreshAccessToken: No refresh token available');
          _isRefreshing = false;
          return false;
        }
      }

      debugPrint(
          'AuthService.refreshAccessToken: Calling /api/auth/token/refresh/');
      debugPrint(
          'AuthService.refreshAccessToken: Using refresh token prefix: ${refresh.length > 8 ? refresh.substring(0, 8) + '...' : refresh}');
      // IMPORTANT: requiresAuth = false to avoid infinite loop - refresh endpoint should NOT have Authorization header
      var resp = await _api.post('/api/auth/token/refresh/',
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refresh': refresh}),
          requiresAuth: false);

      debugPrint(
          'AuthService.refreshAccessToken: Response status ${resp.statusCode}');
      // If server rejects payload key 'refresh', try common alternative 'refresh_token'
      if (resp.statusCode == 401 || resp.statusCode == 400) {
        debugPrint(
            'AuthService.refreshAccessToken: First refresh attempt failed (${resp.statusCode}), trying alternate payload key refresh_token');
        try {
          final resp2 = await _api.post('/api/auth/token/refresh/',
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'refresh_token': refresh}),
              requiresAuth: false);
          debugPrint(
              'AuthService.refreshAccessToken: Alternate attempt status ${resp2.statusCode}');
          resp = resp2;
        } catch (e) {
          debugPrint(
              'AuthService.refreshAccessToken: Alternate refresh attempt failed with error: $e');
        }
      }
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final newAccess = data['access'] as String?;
        final newRefresh = data['refresh'] as String?;
        if (newAccess != null) {
          _token = newAccess;
          try {
            await _storage.write(key: 'access_token', value: _token);
          } catch (_) {}
          _api.setAuthToken(_token);
          debugPrint(
              'AuthService.refreshAccessToken: New access token set successfully');
        }
        if (newRefresh != null) {
          _refreshToken = newRefresh;
          try {
            await _storage.write(key: 'refresh_token', value: _refreshToken);
          } catch (_) {}
        }
        // update user id if available
        try {
          if (_token != null) {
            final parts = _token!.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = base64.normalize(payload);
              final decoded = utf8.decode(base64Url.decode(normalized));
              final Map payloadMap =
                  json.decode(decoded) as Map<String, dynamic>;
              if (payloadMap.containsKey('user_id')) {
                _userId = payloadMap['user_id'].toString();
              }
            }
          }
        } catch (_) {}
        notifyListeners();
        _isRefreshing = false;
        return true;
      }
      debugPrint(
          'AuthService.refreshAccessToken: Refresh failed with status ${resp.statusCode}');
    } catch (e) {
      debugPrint('AuthService.refreshAccessToken: Error during refresh: $e');
    }
    _isRefreshing = false;
    return false;
  }

  /// Handle a refresh failure by clearing tokens and notifying listeners.
  Future<void> handleRefreshFailure() async {
    debugPrint(
        'AuthService.handleRefreshFailure: Clearing tokens and signing out locally');
    _token = null;
    _refreshToken = null;
    _userId = null;
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    } catch (_) {}
    _api.setAuthToken(null);
    notifyListeners();
  }

  /// Register a new user. Returns true on success.
  Future<bool> register(String username, String email, String password,
      String confirmPassword) async {
    try {
      final resp = await _api.post('/api/auth/register/',
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'email': email,
            'password': password,
            'confirm_password': confirmPassword
          }));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verify email with code
  Future<bool> verifyEmail(String email, String code) async {
    try {
      final resp = await _api.post('/api/auth/verify-email/',
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email, 'code': code}));
      if (resp.statusCode == 200 || resp.statusCode == 201) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Resend verification code
  Future<bool> resendVerification(String email) async {
    try {
      final resp = await _api.post('/api/auth/resend-verification-code/',
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email': email}));
      if (resp.statusCode == 200 || resp.statusCode == 201) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}
