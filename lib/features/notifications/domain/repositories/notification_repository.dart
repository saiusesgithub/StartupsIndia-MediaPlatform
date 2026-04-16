import '../models/app_notification.dart';

abstract class NotificationRepository {
  /// Stream of notifications for a specific user, ordered by newest first.
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  /// Mark a specific notification as read.
  Future<void> markAsRead(String userId, String notificationId);

  /// Mark all notifications for a user as read.
  Future<void> markAllAsRead(String userId);

  /// Delete a specific notification.
  Future<void> deleteNotification(String userId, String notificationId);

  /// Save FCM token to the user's document for targeted push notifications.
  Future<void> saveFcmToken(String userId, String token);
}
