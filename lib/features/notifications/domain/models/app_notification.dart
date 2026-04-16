import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { news, follow, interaction }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String avatarLabel;
  final bool isRead;
  final String? payload; // E.g., article ID or user ID

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.avatarLabel,
    this.isRead = false,
    this.payload,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse the notification type safely
    final typeString = data['type'] as String? ?? 'news';
    final type = NotificationType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => NotificationType.news,
    );

    return AppNotification(
      id: doc.id,
      type: type,
      title: data['title'] as String? ?? 'Notification',
      subtitle: data['subtitle'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatarLabel: data['avatarLabel'] as String? ?? 'N',
      isRead: data['isRead'] as bool? ?? false,
      payload: data['payload'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'createdAt': Timestamp.fromDate(createdAt),
      'avatarLabel': avatarLabel,
      'isRead': isRead,
      'payload': payload,
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? subtitle,
    DateTime? createdAt,
    String? avatarLabel,
    bool? isRead,
    String? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      createdAt: createdAt ?? this.createdAt,
      avatarLabel: avatarLabel ?? this.avatarLabel,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }
}
