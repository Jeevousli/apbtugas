import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/create_employee_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../data/datasources/auth_local_datasource.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CreateEmployeeUseCase _createEmployeeUseCase;
  final AuthLocalDataSource _localDataSource;

  AuthProvider({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required CreateEmployeeUseCase createEmployeeUseCase,
    required AuthLocalDataSource localDataSource,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _createEmployeeUseCase = createEmployeeUseCase,
        _localDataSource = localDataSource;

  // ─────────────────────── STATE ──────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserEntity? _currentUser;
  String? _errorMessage;
  bool _rememberMe = false;
  bool _forgotPasswordSent = false;

  // ─────────────────────── GETTERS ────────────────────────────────
  AuthStatus get status => _status;
  UserEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  bool get forgotPasswordSent => _forgotPasswordSent;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ─────────────────────── INIT ───────────────────────────────────
  Future<void> initAuth() async {
    _setStatus(AuthStatus.loading);
    _rememberMe = _localDataSource.isRememberMe;
    try {
      final user = await _getCurrentUserUseCase();
      if (user != null) {
        _currentUser = user;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // ─────────────────────── LOGIN WITH EMAIL ───────────────────────
  Future<bool> loginWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    return _performLogin(
      rememberMe: rememberMe,
      identifier: email,
      loginMode: 'email',
      action: () => _loginUseCase.loginWithEmail(
        email: email,
        password: password,
      ),
    );
  }

  // ─────────────────────── LOGIN WITH NIK ─────────────────────────
  Future<bool> loginWithNik({
    required String nik,
    required String password,
    required bool rememberMe,
  }) async {
    return _performLogin(
      rememberMe: rememberMe,
      identifier: nik,
      loginMode: 'nik',
      action: () => _loginUseCase.loginWithNik(
        nik: nik,
        password: password,
      ),
    );
  }

  Future<bool> _performLogin({
    required bool rememberMe,
    required String identifier,
    required String loginMode,
    required Future<UserEntity> Function() action,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final user = await action();
      _currentUser = user;

      // Save remember me preference
      await _localDataSource.saveRememberMe(
        rememberMe: rememberMe,
        identifier: identifier,
        loginMode: loginMode,
      );
      _rememberMe = rememberMe;
      _setStatus(AuthStatus.authenticated);
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan yang tidak diharapkan';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ─────────────────────── FORGOT PASSWORD ────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setStatus(AuthStatus.loading);
    _forgotPasswordSent = false;
    _errorMessage = null;
    try {
      await _forgotPasswordUseCase(email);
      _forgotPasswordSent = true;
      _setStatus(AuthStatus.unauthenticated);
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengirim email reset password';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ─────────────────────── LOGOUT ─────────────────────────────────
  Future<void> logout() async {
    await _logoutUseCase();
    _currentUser = null;
    _rememberMe = false;
    _forgotPasswordSent = false;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ─────────────────────── HELPERS ────────────────────────────────
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  void resetForgotPasswordState() {
    _forgotPasswordSent = false;
    notifyListeners();
  }

  void updateCurrentUser(UserEntity user) {
    _currentUser = user;
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  // ─────────────────────── CREATE EMPLOYEE (Admin Only) ───────────
  Future<bool> createEmployee({
    required String email,
    required String password,
    required String name,
    required String nik,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      await _createEmployeeUseCase(
        email: email,
        password: password,
        name: name,
        nik: nik,
      );
      _setStatus(AuthStatus.authenticated); // Maintain admin's state as authenticated
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error);
      return false;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan karyawan. Silakan coba lagi.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  // ─────────────────────── SAVED CREDENTIALS ──────────────────────
  String get savedIdentifier => _localDataSource.savedIdentifier;
  String get savedLoginMode => _localDataSource.savedLoginMode;
}
