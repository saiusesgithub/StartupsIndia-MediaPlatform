import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String colorHex; // e.g. "#6C5CE7"
  final int memberCount;
  final DateTime? createdAt;
  final Map<String, dynamic>? lastPost;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.colorHex,
    required this.memberCount,
    this.createdAt,
    this.lastPost,
  });

  Color get color {
    final clean = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  factory CommunityModel.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return CommunityModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '👥',
      colorHex: data['colorHex'] as String? ?? '#6C5CE7',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastPost: data['lastPost'] as Map<String, dynamic>?,
    );
  }
}
