import '../entities/user_entity.dart';

/// Abstract contract for auth operations.
/// Implemented in the data layer.
abstract class AuthRepository {
  /// Login with email and password
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  });

  /// Login with NIK — looks up email in Firestore, then authenticates
  Future<UserEntity> loginWithNik({
    required String nik,
    required String password,
  });

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out current user
  Future<void> logout();

  /// Get the currently authenticated user from Firestore
  Future<UserEntity?> getCurrentUser();

  /// Stream of auth state changes (Firebase Auth)
  Stream<UserEntity?> get authStateChanges;

  /// Update FCM token in Firestore
  Future<void> updateFcmToken(String uid, String token);

  /// Create a new employee account (Admin only)
  Future<UserEntity> createEmployeeAccount({
    required String email,
    required String password,
    required String name,
    required String nik,
  });

  /// Update employee profile details
  Future<UserEntity> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  });

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Upload profile photo and return download URL
  Future<String> uploadProfilePhoto({
    required String uid,
    required String filePath,
  });
}
