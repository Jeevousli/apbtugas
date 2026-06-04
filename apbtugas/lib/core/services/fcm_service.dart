import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final NotificationRepository _notificationRepository;
  String? _currentUserId;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FcmService(this._notificationRepository);

  /// Initialize FCM settings, Local Notifications, and register listeners
  Future<void> initialize() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // 2. Request Local Notifications Permission
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // 3. Initialize Local Notifications Plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Local Notification clicked: ${details.payload}');
      },
    );

    // 4. Request FCM Permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM Permission Status: ${settings.authorizationStatus}');

    // 5. FCM Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Handle token refresh
    _fcm.onTokenRefresh.listen((token) async {
      debugPrint('FCM Token Refreshed: $token');
      if (_currentUserId != null) {
        try {
          await _notificationRepository.saveFcmToken(_currentUserId!, token);
        } catch (e) {
          debugPrint('Error saving refreshed FCM token: $e');
        }
      }
    });

    // 7. Foreground messages listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM Foreground message received: ${message.notification?.title}');
      await _handleIncomingMessage(message);
      
      // Also show it as a local heads-up notification if it has a notification payload
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title ?? 'Pengumuman Baru',
          body: message.notification!.body ?? '',
          id: message.hashCode,
        );
      }
    });

    // 8. Background/Terminated click listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM App opened from notification: ${message.notification?.title}');
    });

    // 9. Schedule Daily Reminders automatically
    await scheduleDailyReminders();
  }

  /// Show an instant local notification (For GPS Fail, Face Fail, Success Clock In)
  Future<void> showLocalNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'kinihadir_channel',
      'KiniHadir Notifications',
      channelDescription: 'Notifikasi absensi dan pengumuman KiniHadir',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
        
    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Schedule the 07:30 and 17:00 daily reminders
  Future<void> scheduleDailyReminders() async {
    // Cancel all previous alarms to avoid duplication
    await _localNotificationsPlugin.cancelAll();

    // Clock In Reminder (07:30)
    await _scheduleDailyNotification(
      id: 101,
      title: 'Waktunya Clock In! ☀️',
      body: 'Jangan lupa untuk melakukan absensi masuk pagi ini.',
      hour: 7,
      minute: 30,
    );

    // Clock Out Reminder (17:00)
    await _scheduleDailyNotification(
      id: 102,
      title: 'Waktunya Clock Out! 🌙',
      body: 'Pekerjaan selesai? Jangan lupa absen pulang ya!',
      hour: 17,
      minute: 0,
    );
    
    debugPrint('Daily reminders scheduled successfully.');
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Pengingat otomatis untuk absensi harian',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Set the current user ID to save the token and parse incoming personal notifications
  Future<void> onUserLoggedIn(String userId) async {
    _currentUserId = userId;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token obtained: $token');
        await _notificationRepository.saveFcmToken(userId, token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Clear the current user context on logout
  void onUserLoggedOut() {
    _currentUserId = null;
  }

  /// Handle parsing and saving incoming message as a NotificationEntity in Firestore
  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    if (_currentUserId == null) return;

    final notification = message.notification;
    if (notification == null) return;

    final typeStr = message.data['type'] ?? 'other';
    
    final notificationEntity = NotificationEntity(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification.title ?? 'Notifikasi Absensi',
      body: notification.body ?? '',
      type: NotificationTypeX.fromString(typeStr),
      timestamp: DateTime.now(),
      isRead: false,
      data: message.data.isNotEmpty ? Map<String, dynamic>.from(message.data) : null,
    );

    try {
      await _notificationRepository.saveNotification(_currentUserId!, notificationEntity);
      debugPrint('Successfully saved foreground notification to Firestore');
    } catch (e) {
      debugPrint('Failed to save notification: $e');
    }
  }
}
