import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;

  NotificationRepositoryImpl({required NotificationRemoteDataSource remote})
      : _remote = remote;

  @override
  Future<List<NotificationEntity>> getNotifications(String userId, {int limit = 50}) {
    return _remote.getNotifications(userId, limit: limit);
  }

  @override
  Stream<List<NotificationEntity>> streamNotifications(String userId, {int limit = 50}) {
    return _remote.streamNotifications(userId, limit: limit);
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) {
    return _remote.markAsRead(userId, notificationId);
  }

  @override
  Future<void> saveNotification(String userId, NotificationEntity notification) {
    final model = NotificationModel.fromEntity(notification);
    return _remote.saveNotification(userId, model);
  }

  @override
  Future<void> saveFcmToken(String userId, String token) {
    return _remote.saveFcmToken(userId, token);
  }
}
