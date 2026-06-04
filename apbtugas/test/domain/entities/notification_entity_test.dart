import 'package:flutter_test/flutter_test.dart';
import 'package:apbtugas/domain/entities/notification_entity.dart';

void main() {
  group('NotificationEntity', () {
    final tDate = DateTime(2024, 1, 1);
    
    final tNotification = NotificationEntity(
      id: 'notif1',
      title: 'Test Notification',
      body: 'This is a test notification',
      type: NotificationType.clockSuccess,
      timestamp: tDate,
      isRead: false,
      data: const {'key': 'value'},
    );

    test('should return correct string for NotificationType', () {
      expect(NotificationType.reminder.value, 'reminder');
      expect(NotificationType.clockSuccess.value, 'clock_success');
      expect(NotificationType.gpsFailed.value, 'gps_failed');
      expect(NotificationType.faceFailed.value, 'face_failed');
      expect(NotificationType.other.value, 'other');
    });

    test('should parse string to correct NotificationType', () {
      expect(NotificationTypeX.fromString('reminder'), NotificationType.reminder);
      expect(NotificationTypeX.fromString('clock_success'), NotificationType.clockSuccess);
      expect(NotificationTypeX.fromString('invalid_type'), NotificationType.other);
    });

    test('should hold correct values', () {
      expect(tNotification.id, 'notif1');
      expect(tNotification.title, 'Test Notification');
      expect(tNotification.isRead, false);
      expect(tNotification.data?['key'], 'value');
      expect(tNotification.timestamp, tDate);
    });

    test('should support value equality', () {
      final tNotification2 = NotificationEntity(
        id: 'notif1',
        title: 'Test Notification',
        body: 'This is a test notification',
        type: NotificationType.clockSuccess,
        timestamp: tDate,
        isRead: false,
        data: const {'key': 'value'},
      );

      expect(tNotification, equals(tNotification2));
    });
  });
}
