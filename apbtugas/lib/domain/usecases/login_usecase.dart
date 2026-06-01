import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  /// Login with email + password
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _repository.loginWithEmail(email: email, password: password);
  }

  /// Login with NIK + password
  Future<UserEntity> loginWithNik({
    required String nik,
    required String password,
  }) {
    return _repository.loginWithNik(nik: nik, password: password);
  }
}
