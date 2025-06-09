// ✅ databaseSvc.dart (imageUrl 필드 포함 및 fromDoc/postId 정리)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 모집글 데이터 모델
class RecruitPost {
  final String postId;
  final String title;
  final String hostId;
  final String content;
  final String placeName;
  final GeoPoint location;
  final String foodType;
  final int maxParticipants;
  final String genderLimit;
  final Timestamp meetTime;
  final Timestamp createdAt;
  final String status;
  final List<String> participantIds;
  final String? imageUrl; // ✅ 추가됨

  RecruitPost({
    required this.postId,
    required this.title,
    required this.hostId,
    required this.content,
    required this.placeName,
    required this.location,
    required this.foodType,
    required this.maxParticipants,
    required this.genderLimit,
    required this.meetTime,
    required this.createdAt,
    required this.status,
    required this.participantIds,
    this.imageUrl,
  });

  factory RecruitPost.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecruitPost(
      postId: doc.id, // ← Firestore 문서 ID 사용
      title: data['title'] ?? '',
      hostId: data['hostId'] ?? '',
      content: data['content'] ?? '',
      placeName: data['placeName'] ?? '',
      location: data['location'] ?? GeoPoint(0, 0),
      foodType: data['foodType'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
      genderLimit: data['genderLimit'] ?? 'any',
      meetTime: data['meetTime'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'open',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'hostId': hostId,
      'content': content,
      'placeName': placeName,
      'location': location,
      'foodType': foodType,
      'maxParticipants': maxParticipants,
      'genderLimit': genderLimit,
      'meetTime': meetTime,
      'createdAt': createdAt,
      'status': status,
      'participantIds': participantIds,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class RecruitPostDBS {
  static CollectionReference postsRef = FirebaseFirestore.instance.collection('posts');

  static Future<void> addPost(RecruitPost post) async {
    await postsRef.doc(post.postId).set(post.toMap());
  }

  static Stream<List<RecruitPost>> getPostsStream() {
    return postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) => query.docs.map((doc) => RecruitPost.fromDoc(doc)).toList());
  }
}