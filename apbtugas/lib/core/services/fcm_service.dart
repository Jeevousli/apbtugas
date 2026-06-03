import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final NotificationRepository _notificationRepository;
  String? _currentUserId;

  FcmService(this._notificationRepository);

  /// Initialize FCM settings and register listeners
  Future<void> initialize() async {
    // Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM Permission Status: ${settings.authorizationStatus}');

    // Handle token refresh
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

    // Foreground messages listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM Foreground message received: ${message.notification?.title}');
      await _handleIncomingMessage(message);
    });

    // Background/Terminated click listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM App opened from notification: ${message.notification?.title}');
    });
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
