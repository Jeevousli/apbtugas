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
}
