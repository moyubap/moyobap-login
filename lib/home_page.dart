import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

// ------------------- Notification Page -------------------
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림'), backgroundColor: Colors.lightBlue),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildNotificationItem('새로운 밥 친구 채팅이 도착했습니다!', '2025-05-01', '10:12'),
          _buildNotificationItem('채팅에 새 메시지가 도착했습니다.', '2025-05-01', '09:48'),
          _buildNotificationItem('OO님의 밥 친구 요청이 마감되었습니다.', '2025-04-30', '17:30'),
          _buildNotificationItem('오늘 서울에서 모임이 있습니다!', '2025-04-30', '08:00'),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String message, String date, String time) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- Write Page -------------------
class WritePage extends StatefulWidget {
  const WritePage({super.key});

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? selectedLocation;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerPage()),
    );
    if (result != null) {
      setState(() {
        selectedLocation = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 쓰기'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('임시저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: '제목을 입력해주세요.'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(hintText: '#태그를 입력해주세요. 예: #점심 #밥약'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '밥 친구들과 가볍게 얘기해보세요.'),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                color: Colors.grey[200],
                child: _selectedImage == null
                    ? const Center(child: Icon(Icons.link))
                    : Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('만남 희망 장소'),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              onTap: _selectLocation,
              decoration: InputDecoration(
                hintText: selectedLocation ?? '위치 추가',
                suffixIcon: const Icon(Icons.chevron_right),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- Location Picker Page -------------------
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  bool isManualInput = false;
  TextEditingController manualLocationController = TextEditingController();

  final List<String> locationList = ['서울역', '강남역', '김포공항역', '작전역', '홍대입구역'];

  @override
  void dispose() {
    manualLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('위치 선택')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...locationList.map((loc) => ListTile(
            title: Text(loc),
            onTap: () => Navigator.pop(context, loc),
          )),
          ListTile(
            title: const Text('직접입력'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              setState(() {
                isManualInput = true;
              });
            },
          ),
          if (isManualInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: manualLocationController,
              decoration: const InputDecoration(
                labelText: '직접 입력할 위치',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final manualText = manualLocationController.text.trim();
                if (manualText.isNotEmpty) {
                  Navigator.pop(context, manualText);
                }
              },
              child: const Text('위치 선택'),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------- Post Detail Page -------------------
class PostDetailPage extends StatelessWidget {
  final String title;

  const PostDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글 상세')),
      body: Center(child: Text('제목: $title')),
    );
  }
}

// ------------------- Home Page -------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> locations = ['위치', '부산', '서울', '대구', '광주', '대전', '울산', '인천'];
  final List<String> menus = ['메뉴', '한식', '일식', '중식', '양식', '분식', '디저트', '패스트푸드'];

  String? selectedLocation = '위치';
  String? selectedMenu = '메뉴';

  List<Map<String, String>> posts = [
    {'title': '부산 ○○구에서 밥 친구 구해요', 'views': '2.7k', 'comments': '2', 'image': 'assets/images/pexels-marina-zasorina-9419203.jpg'},
    {'title': '오늘 점심 같이 드실 분!', 'views': '5.6k', 'comments': '5', 'image': 'assets/images/lunch.jpeg'},
    {'title': '국밥 먹을 사람?', 'views': '4.0k', 'comments': '3', 'image': 'assets/images/gukbap.jpeg'},
    {'title': '혼밥 싫은 사람 모여라', 'views': '1.1k', 'comments': '1', 'image': 'assets/images/japanfood.jpeg'},
    {'title': '매일 점심 같이 먹어요', 'views': '3.2k', 'comments': '0', 'image': 'assets/images/chicken.jpeg'},
    {'title': '테스트용 게시글입니다1', 'views': '100', 'comments': '0', 'image': 'assets/images/japanfood.jpeg'},
    {'title': '테스트용 게시글입니다2', 'views': '89', 'comments': '0', 'image': 'assets/images/lunch.jpeg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.rice_bowl, color: Colors.white),
            SizedBox(width: 8),
            Text('모여밥', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '위치'),
                      items: locations.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLocation = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedMenu,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '메뉴'),
                      items: menus.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMenu = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) => _buildPostItem(context, posts[index]),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const WritePage()));
        },
        backgroundColor: Colors.lightBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, Map<String, String> post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailPage(title: post['title']!)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(post['views']!),
                          const SizedBox(width: 12),
                          const Icon(Icons.comment, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${post['comments']} Comments'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.asset(
                  post['image']!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
