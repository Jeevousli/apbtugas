import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/upload_profile_photo_usecase.dart';
import 'auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final UpdateProfileUseCase _updateProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final UploadProfilePhotoUseCase _uploadProfilePhotoUseCase;

  ProfileProvider({
    required UpdateProfileUseCase updateProfileUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required UploadProfilePhotoUseCase uploadProfilePhotoUseCase,
  })  : _updateProfileUseCase = updateProfileUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _uploadProfilePhotoUseCase = uploadProfilePhotoUseCase;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  bool _isUploadingPhoto = false;
  bool get isUploadingPhoto => _isUploadingPhoto;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Update employee profile info (name, phone)
  Future<bool> updateProfile({
    required AuthProvider authProvider,
    required String uid,
    String? name,
    String? phone,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _updateProfileUseCase.execute(
        uid: uid,
        name: name,
        phone: phone,
      );
      authProvider.updateCurrentUser(updatedUser);
      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isChangingPassword = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _changePasswordUseCase.execute(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isChangingPassword = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthFailure: ', '');
      _isChangingPassword = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile picture and update user photo URL
  Future<bool> uploadProfilePhoto({
    required AuthProvider authProvider,
    required String uid,
    required String filePath,
  }) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final photoUrl = await _uploadProfilePhotoUseCase.execute(
        uid: uid,
        filePath: filePath,
      );
      
      // Update in Firestore
      final updatedUser = await _updateProfileUseCase.execute(
        uid: uid,
        photoUrl: photoUrl,
      );
      
      authProvider.updateCurrentUser(updatedUser);
      _isUploadingPhoto = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
