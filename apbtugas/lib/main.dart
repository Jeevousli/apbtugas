import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_theme.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/notification_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/attendance_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'core/services/fcm_service.dart';
import 'domain/usecases/create_employee_usecase.dart';
import 'domain/usecases/forgot_password_usecase.dart';
import 'domain/usecases/get_current_user_usecase.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/logout_usecase.dart';
import 'domain/usecases/update_profile_usecase.dart';
import 'domain/usecases/change_password_usecase.dart';
import 'domain/usecases/upload_profile_photo_usecase.dart';
import 'firebase_options.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/attendance_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/screens/admin/create_employee_screen.dart';
import 'presentation/screens/admin/admin_employee_list_screen.dart';
import 'presentation/screens/admin/admin_employee_detail_screen.dart';
import 'presentation/screens/admin/admin_attendance_logs_screen.dart';
import 'presentation/screens/admin/admin_kpi_charts_screen.dart';
import 'presentation/screens/admin/admin_map_overview_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/admin_dashboard_screen.dart';
import 'presentation/screens/dashboard/employee_dashboard_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/employee/attendance_detail_screen.dart';
import 'presentation/screens/employee/edit_profile_screen.dart';
import 'presentation/screens/employee/change_password_screen.dart';

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

  // ── Firebase App Check ──────────────────────────────────────
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  // FCM Setup
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
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

    // Notification dependencies
    final notificationRemoteDataSource = NotificationRemoteDataSource(
      firestore: FirebaseFirestore.instance,
    );
    final notificationRepository = NotificationRepositoryImpl(
      remote: notificationRemoteDataSource,
    );
    final fcmService = FcmService(notificationRepository);
    fcmService.initialize();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider(
              loginUseCase: LoginUseCase(authRepository),
              logoutUseCase: LogoutUseCase(authRepository),
              forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
              getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
              createEmployeeUseCase: CreateEmployeeUseCase(authRepository),
              localDataSource: localDataSource,
            );

            // Reactively bind FCM token update / removal to Auth status
            authProvider.addListener(() {
              final user = authProvider.currentUser;
              if (authProvider.isAuthenticated && user != null) {
                fcmService.onUserLoggedIn(user.uid);
              } else {
                fcmService.onUserLoggedOut();
              }
            });

            return authProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => AttendanceProvider(repository: attendanceRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            updateProfileUseCase: UpdateProfileUseCase(authRepository),
            changePasswordUseCase: ChangePasswordUseCase(authRepository),
            uploadProfilePhotoUseCase: UploadProfilePhotoUseCase(authRepository),
          ),
        ),
        // Admin Monitoring Provider
        ChangeNotifierProvider(
          create: (_) => AdminProvider(
            firestore: FirebaseFirestore.instance,
          ),
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
        // ── Core Routes ─────────────────────────────────────────
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
        GoRoute(
          path: AppRoutes.attendanceDetail,
          builder: (context, state) {
            final recordId = state.uri.queryParameters['id'] ?? '';
            return AttendanceDetailScreen(recordId: recordId);
          },
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.changePassword,
          builder: (context, state) => const ChangePasswordScreen(),
        ),

        // ── Admin Monitoring Routes ──────────────────────────────
        GoRoute(
          path: AppRoutes.adminEmployeeList,
          builder: (context, state) => const AdminEmployeeListScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminEmployeeDetail,
          builder: (context, state) {
            final uid = state.uri.queryParameters['uid'] ?? '';
            return AdminEmployeeDetailScreen(uid: uid);
          },
        ),
        GoRoute(
          path: AppRoutes.adminAttendanceLogs,
          builder: (context, state) {
            final uid = state.uri.queryParameters['uid'] ?? '';
            final name = state.uri.queryParameters['name'] ?? 'Karyawan';
            return AdminAttendanceLogsScreen(
                uid: uid, employeeName: name);
          },
        ),
        GoRoute(
          path: AppRoutes.adminKpiCharts,
          builder: (context, state) => const AdminKpiChartsScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminMapOverview,
          builder: (context, state) => const AdminMapOverviewScreen(),
        ),
      ],
    );
  }
}
