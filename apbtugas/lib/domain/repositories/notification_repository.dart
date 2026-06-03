import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Fetch list of notifications for a specific user
  Future<List<NotificationEntity>> getNotifications(String userId, {int limit = 50});

  /// Realtime stream of notifications for a specific user
  Stream<List<NotificationEntity>> streamNotifications(String userId, {int limit = 50});

  /// Mark a specific notification as read
  Future<void> markAsRead(String userId, String notificationId);

  /// Save a notification to Firestore
  Future<void> saveNotification(String userId, NotificationEntity notification);

  /// Save the device's FCM token to Firestore
  Future<void> saveFcmToken(String userId, String token);
}
