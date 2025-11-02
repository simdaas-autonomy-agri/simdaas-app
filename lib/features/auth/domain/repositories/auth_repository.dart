import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signIn(String email, String password);
  Future<void> logout();
}
