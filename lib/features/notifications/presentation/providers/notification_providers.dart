import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/firebase_notification_repository_impl.dart';
import '../../domain/models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseNotificationRepositoryImpl(firestore: firestore);
});

final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUserNotifications(user.uid);
});

// A provider block that automatically saves the FCM token whenever the user or token changes,
// ensuring the latest token is written to the user's Firestore document.
final fcmTokenSyncProvider = Provider.autoDispose<void>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return;

  final repository = ref.watch(notificationRepositoryProvider);

  // Get the initial token
  FirebaseMessaging.instance.getToken().then((token) {
    if (token != null) {
      repository.saveFcmToken(user.uid, token);
    }
  });

  // Listen to token refreshes
  final sub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    repository.saveFcmToken(user.uid, token);
  });

  ref.onDispose(() => sub.cancel());
});
