import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String websiteUrl;
  final int followersCount;
  final int followingCount;
  final int newsCount;
  // ── Onboarding ────────────────────────────────────────────────────────────
  final String role;              // e.g. 'founder', 'student'
  final List<String> interests;   // e.g. ['ai', 'saas']
  final bool onboardingCompleted;

  const UserModel({
    required this.uid,
    this.username = '',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.websiteUrl,
    required this.followersCount,
    required this.followingCount,
    required this.newsCount,
    this.role = '',
    this.interests = const [],
    this.onboardingCompleted = false,
  });

  UserModel copyWith({
    String? uid,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? websiteUrl,
    int? followersCount,
    int? followingCount,
    int? newsCount,
    String? role,
    List<String>? interests,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      newsCount: newsCount ?? this.newsCount,
      role: role ?? this.role,
      interests: interests ?? this.interests,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      username: data['username'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      websiteUrl: data['websiteUrl'] as String? ?? '',
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      newsCount: (data['newsCount'] as num?)?.toInt() ?? 0,
      role: data['role'] as String? ?? '',
      interests: List<String>.from(data['interests'] as List? ?? []),
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'uid': uid,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'websiteUrl': websiteUrl,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'newsCount': newsCount,
      'role': role,
      'interests': interests,
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
