import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ChatDetailPage extends StatefulWidget {
  final String otherUserId;
  final String chatRoomId;

  const ChatDetailPage({
    Key? key,
    required this.otherUserId,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioFilePath;

  final Map<String, String> _userNicknames = {};
  String? otherUserProfileUrl;
  String? otherUserEmail;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _loadOtherUserProfile(); // 상대방 프로필 로드
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  // 마이크 권한 요청
  Future<bool> _requestPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  // 녹음 시작
  Future<void> _startRecording() async {
    bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('마이크 권한이 필요합니다!')),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    _audioFilePath = '${dir.path}/temp_sound.aac';

    await _recorder.openRecorder();
    await _recorder.startRecorder(
      toFile: _audioFilePath,
      codec: Codec.aacADTS,
    );
    setState(() {
      _isRecording = true;
    });
  }

  // 녹음 종료
  Future<File?> _stopRecording() async {
    String? path = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (path != null) return File(path);
    return null;
  }

  // 상대방 프로필 불러오기
  Future<void> _loadOtherUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        otherUserProfileUrl = data['profileImage'];
        otherUserEmail = data['email'];
      });
    }
  }

  // 네이버 CSR STT 함수
  Future<String?> sttWithNaver(File audioFile) async {
    final String clientId = '여기에_클라이언트_ID_입력';
    final String clientSecret = '여기에_클라이언트_SECRET_입력';

    final url = Uri.parse('https://naveropenapi.apigw.ntruss.com/recog/v1/stt?lang=Kor');

    final headers = {
      'X-NCP-APIGW-API-KEY-ID': clientId,
      'X-NCP-APIGW-API-KEY': clientSecret,
      'Content-Type': 'application/octet-stream',
    };

    final audioBytes = await audioFile.readAsBytes();

    final response = await http.post(url, headers: headers, body: audioBytes);

    if (response.statusCode == 200) {
      final jsonData = json.decode(utf8.decode(response.bodyBytes));
      return jsonData['text'] as String?;
    } else {
      print('STT 변환 실패: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  // 마이크 버튼 콜백
  void _onMicButtonPressed() async {
    if (!_isRecording) {
      await _startRecording();
    } else {
      File? audioFile = await _stopRecording();
      if (audioFile != null) {
        String? resultText = await sttWithNaver(audioFile);
        if (resultText != null && resultText.isNotEmpty) {
          setState(() {
            _messageController.text = resultText;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('STT 변환 실패')),
          );
        }
      }
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  // 채팅방 ID 생성 (사용자 ID를 정렬하여 중복 방 생성 방지)
  String getChatRoomId() {
    List<String> ids = [currentUser!.uid, widget.otherUserId];
    ids.sort();
    return ids.join("_");
  }

  // 닉네임 불러오기 & 캐싱
  Future<String> _getNickname(String userId) async {
    if (_userNicknames.containsKey(userId)) {
      return _userNicknames[userId]!;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    String nickname = doc.data()?['nickname'] ?? '알수없음';
    _userNicknames[userId] = nickname;
    return nickname;
  }

  // 메시지 전송
  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatRoomId = getChatRoomId();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'receiverId': widget.otherUserId,
      'text': text,
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();

    // 새 메시지 위치로 스크롤 이동
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 이미지 메시지 전송
  void sendImageMessage(File imageFile) async {
    final chatRoomId = getChatRoomId();
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'receiverId': widget.otherUserId,
      'imagePath': imageFile.path,
      'timestamp': Timestamp.now(),
    });
  }

  // 첨부파일 선택 옵션 보여주기
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('사진 선택'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  sendImageMessage(File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  sendImageMessage(File(photo.path));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomId = getChatRoomId();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: otherUserProfileUrl != null
                  ? NetworkImage(otherUserProfileUrl!)
                  : const AssetImage('assets/users/profile1.jpg') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(otherUserEmail ?? '상대방'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // 내림차순 정렬 (최신 메시지 위)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // 리스트를 아래에서부터 위로 쌓기 (최신 메시지부터)
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final senderId = data['senderId'] ?? '';
                    final isMe = senderId == currentUser!.uid;

                    // 이미지 메시지 처리
                    if (data.containsKey('imagePath')) {
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: Image.file(
                            File(data['imagePath']),
                            width: 200,
                          ),
                        ),
                      );
                    }

                    // 텍스트 메시지 + 닉네임 표시
                    return FutureBuilder<String>(
                      future: _getNickname(senderId),
                      builder: (context, nickSnapshot) {
                        String nickname = nickSnapshot.connectionState == ConnectionState.done
                            ? (nickSnapshot.data ?? '알수없음')
                            : '...';

                        return Container(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  nickname,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blueAccent : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  data['text'] ?? '',
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 메시지 입력 및 버튼 영역
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                  color: _isRecording ? Colors.red : Colors.black,
                  onPressed: _onMicButtonPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
