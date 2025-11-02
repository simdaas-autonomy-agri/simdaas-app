import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class Login implements UseCase<void, LoginParams> {
  final AuthRepository repository;
  Login(this.repository);

  @override
  Future<void> call(LoginParams params) async {
    await repository.signIn(params.email, params.password);
  }
}

class LoginParams {
  final String email;
  final String password;
  LoginParams({required this.email, required this.password});
}
