import 'package:flutter/material.dart';

import 'post_item.dart';             // 이제 RecruitPost 기반으로 구현되어야 함
import 'notification_page.dart';
import 'write_page.dart';
import '../databaseSvc.dart';       // RecruitPost, RecruitPostDBS 사용

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  final locations = [
    '위치',
    '부산',
    '서울',
    '대구',
    '광주',
    '대전',
    '울산',
    '인천',
  ];
  final menus = [
    '메뉴',
    '한식',
    '일식',
    '중식',
    '양식',
    '분식',
    '디저트',
    '패스트푸드',
  ];

  String selectedLocation = '위치';
  String selectedMenu = '메뉴';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Row(
          children: [
            Icon(Icons.rice_bowl, color: Colors.white),
            SizedBox(width: 8),
            Text('모여밥',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 검색창
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // 필터 드롭다운
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: '위치'),
                      items: locations
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedLocation = v ?? '위치'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedMenu,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), labelText: '메뉴'),
                      items: menus
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedMenu = v ?? '메뉴'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 게시글 목록 - 오직 RecruitPost만 사용!
            StreamBuilder<List<RecruitPost>>(
              stream: RecruitPostDBS.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('게시글이 없습니다.'));
                }
                final recruitPosts = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recruitPosts.length,
                  itemBuilder: (_, i) => PostItem(recruitPosts[i]), // PostItem이 RecruitPost 타입을 받아야 함!
                );
              },
            ),
          ],
        ),
      ),

      // 글쓰기 버튼
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WritePage()),
        ),
      ),
    );
  }
}
