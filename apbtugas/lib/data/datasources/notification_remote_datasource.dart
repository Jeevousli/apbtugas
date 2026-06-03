import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final FirebaseFirestore _firestore;

  NotificationRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference _notificationsCollection(String userId) {
    return _firestore.collection('notifications').doc(userId).collection('items');
  }

  Future<List<NotificationModel>> getNotifications(String userId, {int limit = 50}) async {
    final query = await _notificationsCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  Stream<List<NotificationModel>> streamNotifications(String userId, {int limit = 50}) {
    return _notificationsCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsCollection(userId).doc(notificationId).update({'isRead': true});
  }

  Future<void> saveNotification(String userId, NotificationModel notification) async {
    await _notificationsCollection(userId).add(notification.toFirestore());
  }

  Future<void> saveFcmToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({'fcmToken': token});
  }
}
