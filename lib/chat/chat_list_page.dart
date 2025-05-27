import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  bool isEditing = false;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // 예시 채팅방 리스트
  List<Map<String, dynamic>> chatRooms = [
    {
      'chatRoomId': 'uid1_uid2',
      'otherUserId': '상대_UID',
      'name': '테스트 유저',
      'lastMessage': '안녕하세요!',
      'unreadCount': 2,
      'isGroup': false,
      'memberCount': 2,
    },
    {
      'chatRoomId': 'uid3_uid4',
      'otherUserId': '다른_UID',
      'name': '그룹채팅방',
      'lastMessage': '모두 모이세요',
      'unreadCount': 0,
      'isGroup': true,
      'memberCount': 5,
    },
  ];

  void _showCreateChatDialog(BuildContext context) {
    // 사용자 선택 모달 등으로 확장 가능
    showModalBottomSheet(
      context: context,
      builder: (_) => Center(child: Text("채팅방 생성 기능 구현 예정")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        automaticallyImplyLeading: false,
        leading: TextButton(
          onPressed: () {
            setState(() {
              isEditing = !isEditing;
            });
          },
          child: Text(
            isEditing ? '완료' : '편집',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        centerTitle: true,
        title: const Text('채팅', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            onPressed: () {
              _showCreateChatDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '채팅방을 검색하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chat = chatRooms[index];
                final isGroupChat = chat['isGroup'];
                final unread = chat['unreadCount'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: Stack(
                    children: [
                      isGroupChat
                          ? CircleAvatar(
                        backgroundColor: Colors.blueGrey[100],
                        child: Text(
                          '${chat['memberCount']}',
                          style: const TextStyle(color: Colors.black),
                        ),
                      )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      if (unread > 0)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Text(
                        chat['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    chat['lastMessage'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          otherUserId: chat['otherUserId'],
                          chatRoomId: chat['chatRoomId'],
                        ),
                      ),
                    );
                  },
                  trailing: isEditing
                      ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        chatRooms.removeAt(index);
                      });
                    },
                  )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
