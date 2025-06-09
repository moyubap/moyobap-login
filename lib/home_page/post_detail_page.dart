// ✅ post_detail_page.dart (likes 필드 형 변환 오류 대응 포함)
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'write_page.dart';
import '../databaseSvc.dart';
import 'user_profile_page.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.post});
  final RecruitPost post;

  bool get isMyPost {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && post.hostId == user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          if (isMyPost) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: "수정",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WritePage(post: post),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "삭제",
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("정말 삭제하시겠습니까?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("취소"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("삭제"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(post.postId)
                      .delete();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            post.imageUrl != null && post.imageUrl!.isNotEmpty
                ? Image.network(
              post.imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            )
                : Image.asset(
              'assets/images/점심밥.jpeg',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(post.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('모집 중',
                            style:
                            TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(post.hostId)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final raw = snapshot.data!.data();
                      if (raw == null) return const SizedBox.shrink();
                      final user = raw as Map<String, dynamic>;
                      final nickname = user['nickname'] ?? post.hostId;
                      final profileUrl = user['profileImage'];
                      final intro = user['bio'] ?? '';
                      final major = user['major'] ?? '';
                      final university = user['university'] ?? '';
                      final rawLikes = user['likes'];
                      List<String> likes = [];
                      if (rawLikes is List) {
                        likes = List<String>.from(rawLikes);
                      } else if (rawLikes is String) {
                        likes = rawLikes.split(',').map((e) => e.trim()).toList();
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(
                                username: nickname,
                                university: university,
                                imagePath: profileUrl ?? '',
                                major: major,
                                intro: intro,
                                favoriteFoods: likes,
                                location: post.placeName,
                                postCount: 0,
                                chatCount: 0,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                                  ? NetworkImage(profileUrl)
                                  : const AssetImage('assets/users/profile1.jpg') as ImageProvider,
                              radius: 20,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nickname,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(intro, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('📍 위치: ${post.placeName}'),
                  Text('📅 날짜: ${post.meetTime.toDate().toString().split(" ")[0]}'),
                  Text('⏰ 시간: ${post.meetTime.toDate().toString().split(" ")[1].substring(0, 5)}'),
                  Text('🍱 식사 종류: ${post.foodType}'),
                  const SizedBox(height: 16),
                  Text(post.content, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(post.placeName)}',
                      );
                      if (!await launchUrl(uri)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('지도를 열 수 없습니다.')),
                        );
                      }
                    },
                    child: Text(
                      '📍 지도 위치: ${post.placeName}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('관심 0 ∙ 조회수 0',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
