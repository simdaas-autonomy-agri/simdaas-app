import '../../../auth/domain/entities/user.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../../auth/domain/repositories/auth_repository.dart' as domain;

class AuthRepositoryImpl implements domain.AuthRepository {
  final AuthRemoteDataSource remote;
  AuthRepositoryImpl(this.remote);

  @override
  Future<User> signIn(String email, String password) async {
    final model = await remote.signIn(email, password);
    return User(id: model.id, email: model.email);
  }

  @override
  Future<void> logout() async {
    return remote.logout(null);
  }
}
