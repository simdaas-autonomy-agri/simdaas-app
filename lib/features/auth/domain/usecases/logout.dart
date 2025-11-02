import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class Logout implements UseCase<void, void> {
  final AuthRepository repository;
  Logout(this.repository);

  @override
  Future<void> call(void params) async {
    await repository.logout();
  }
}
