// ✅ post_item.dart (등록한 이미지 적용, 기본 이미지 fallback)
import 'package:flutter/material.dart';
import '../databaseSvc.dart';
import 'post_detail_page.dart';

class PostItem extends StatelessWidget {
  const PostItem(this.post, {super.key});
  final RecruitPost post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: post.imageUrl != null && post.imageUrl!.isNotEmpty
                  ? NetworkImage(post.imageUrl!)
                  : const AssetImage('assets/images/점심밥.jpeg') as ImageProvider,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '0',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '0',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
