import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_theme.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'domain/usecases/create_employee_usecase.dart';
import 'domain/usecases/forgot_password_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'firebase_options.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/attendance_provider.dart';
import 'presentation/screens/admin/create_employee_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/admin_dashboard_screen.dart';
import 'presentation/screens/dashboard/employee_dashboard_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

// FCM background handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM Setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupFCM();

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

Future<void> _setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  // Request notification permission
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('FCM permission: ${settings.authorizationStatus}');

  // Foreground notification handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
  });
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Dependency injection
    final localDataSource = AuthLocalDataSource(prefs);
    final remoteDataSource = AuthRemoteDataSource(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
    final authRepository = AuthRepositoryImpl(
      remote: remoteDataSource,
      local: localDataSource,
    );
    final attendanceRepository = AttendanceRepositoryImpl(
      firestore: FirebaseFirestore.instance,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(authRepository),
            logoutUseCase: LogoutUseCase(authRepository),
            forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
            getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
            createEmployeeUseCase: CreateEmployeeUseCase(authRepository),
            localDataSource: localDataSource,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(repository: attendanceRepository),
        ),
      ],
      child: MaterialApp.router(
        title: 'APB Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _buildRouter(),
      ),
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.employeeDashboard,
          builder: (context, state) => const EmployeeDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminCreateEmployee,
          builder: (context, state) => const CreateEmployeeScreen(),
        ),
      ],
    );
  }
}
