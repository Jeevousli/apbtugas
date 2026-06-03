import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  StreamSubscription<List<NotificationEntity>>? _subscription;

  NotificationProvider(this._repository);

  List<NotificationEntity> _notifications = [];
  List<NotificationEntity> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Subscribe to realtime notification stream for user
  void subscribeToNotifications(String userId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _repository.streamNotifications(userId).listen(
      (data) {
        _notifications = data;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Cancel subscription
  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _notifications = [];
    notifyListeners();
  }

  /// Mark specific notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _repository.markAsRead(userId, notificationId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
