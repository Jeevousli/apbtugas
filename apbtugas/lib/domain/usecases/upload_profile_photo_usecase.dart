import '../repositories/auth_repository.dart';

class UploadProfilePhotoUseCase {
  final AuthRepository _repository;

  UploadProfilePhotoUseCase(this._repository);

  Future<String> execute({
    required String uid,
    required String filePath,
  }) {
    return _repository.uploadProfilePhoto(
      uid: uid,
      filePath: filePath,
    );
  }
}
