import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'package:simdaas/core/services/auth_service.dart';

// provider to create a repository wired to ApiService
final authRepositoryProvider = Provider((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthRepositoryImpl(AuthRemoteDataSourceImpl(api));
});

class AuthState {
  final bool loading;
  final User? user;
  final String? error;
  AuthState({this.loading = false, this.user, this.error});
}

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final Ref _ref;
  AuthNotifier(Ref ref)
      : _ref = ref,
        super(AsyncValue.data(AuthState(loading: false)));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Use central AuthService to perform sign in so tokens are persisted and ApiService gets the token
      final authService = _ref.read(authServiceProvider);
      final ok = await authService.signIn(email, password);
      if (!ok) throw Exception('Login failed');
      // Build a User entity from AuthService decoded user id (if available)
      final userId = authService.currentUserId ?? '';
      final user = User(id: userId, email: email);
      state = AsyncValue.data(AuthState(loading: false, user: user));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(
    (ref) => AuthNotifier(ref));
