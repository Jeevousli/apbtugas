import 'package:equatable/equatable.dart';

enum NotificationType { reminder, clockSuccess, gpsFailed, faceFailed, other }

extension NotificationTypeX on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.clockSuccess:
        return 'clock_success';
      case NotificationType.gpsFailed:
        return 'gps_failed';
      case NotificationType.faceFailed:
        return 'face_failed';
      case NotificationType.other:
        return 'other';
    }
  }

  static NotificationType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'reminder':
        return NotificationType.reminder;
      case 'clock_success':
        return NotificationType.clockSuccess;
      case 'gps_failed':
        return NotificationType.gpsFailed;
      case 'face_failed':
        return NotificationType.faceFailed;
      default:
        return NotificationType.other;
    }
  }
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.data,
  });

  @override
  List<Object?> get props => [id, title, body, type, timestamp, isRead, data];
}
