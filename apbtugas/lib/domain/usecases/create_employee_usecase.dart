import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CreateEmployeeUseCase {
  final AuthRepository _repository;

  CreateEmployeeUseCase(this._repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String name,
    required String nik,
  }) {
    return _repository.createEmployeeAccount(
      email: email,
      password: password,
      name: name,
      nik: nik,
    );
  }
}
