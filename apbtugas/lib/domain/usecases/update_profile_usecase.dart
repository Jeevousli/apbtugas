import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<UserEntity> execute({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  }) {
    return _repository.updateProfile(
      uid: uid,
      name: name,
      phone: phone,
      photoUrl: photoUrl,
    );
  }
}
