import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<UserEntity> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _remote.loginWithEmail(email: email, password: password);
    await _local.setLoggedIn(true);
    return user;
  }

  @override
  Future<UserEntity> loginWithNik({
    required String nik,
    required String password,
  }) async {
    final user = await _remote.loginWithNik(nik: nik, password: password);
    await _local.setLoggedIn(true);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _remote.sendPasswordResetEmail(email);
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
    await _local.clearAuthData();
  }

  @override
  Future<UserEntity?> getCurrentUser() {
    return _remote.getCurrentUser();
  }

  @override
  Stream<UserEntity?> get authStateChanges => _remote.authStateChanges;

  @override
  Future<void> updateFcmToken(String uid, String token) {
    return _remote.updateFcmToken(uid, token);
  }

  @override
  Future<UserEntity> createEmployeeAccount({
    required String email,
    required String password,
    required String name,
    required String nik,
  }) {
    return _remote.createEmployeeAccount(
      email: email,
      password: password,
      name: name,
      nik: nik,
    );
  }
}
