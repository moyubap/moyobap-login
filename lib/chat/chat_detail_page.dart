import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_sound/flutter_sound.dart';            // [녹음 기능 추가]
import 'package:permission_handler/permission_handler.dart';  // [녹음 기능 추가]
import 'package:path_provider/path_provider.dart';            // [녹음 기능 추가]
import 'dart:io';                                            // [녹음 기능 추가]

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

  // [녹음 기능 추가]
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  // [녹음 기능 추가] 마이크 권한 요청
  Future<bool> _requestPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  // [녹음 기능 추가] 녹음 시작
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

  // [녹음 기능 추가] 녹음 종료
  Future<File?> _stopRecording() async {
    String? path = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (path != null) return File(path);
    return null;
  }

  // [녹음 기능 추가] 마이크 버튼 콜백
  void _onMicButtonPressed() async {
    if (!_isRecording) {
      await _startRecording();
    } else {
      File? audioFile = await _stopRecording();
      if (audioFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('녹음 완료: ${audioFile.path}')),
        );
        // TODO: 여기서 STT 연동 등 추가 가능!
      }
    }
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('채팅'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser!.uid;

                    return Container(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Container(
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
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // [녹음 기능 추가] 마이크 버튼
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: _isRecording ? Colors.red : Colors.black,
                  ),
                  onPressed: _onMicButtonPressed,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => sendMessage(),
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요...',
                    ),
                  ),
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
