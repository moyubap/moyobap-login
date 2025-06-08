import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_sound/flutter_sound.dart';            // [녹음 기능 추가]
import 'package:permission_handler/permission_handler.dart';  // [녹음 기능 추가]
import 'package:path_provider/path_provider.dart';            // [녹음 기능 추가]
import 'package:http/http.dart' as http;                      // [STT 연동 추가]
import 'dart:convert';                                        // [STT 연동 추가]
import 'dart:io';                                             // [녹음/업로드 기능 추가]

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

  // [녹음 기능 변수]
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

  // [마이크 권한 요청]
  Future<bool> _requestPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  // [녹음 시작]
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

  // [녹음 종료]
  Future<File?> _stopRecording() async {
    String? path = await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (path != null) return File(path);
    return null;
  }

  // [네이버 CSR STT 함수]
  Future<String?> sttWithNaver(File audioFile) async {
    final String clientId = 'cwu02jjjiv';         // 예: cwu02ijijw
    final String clientSecret = 'vrZrEU6Ffc58Z01vJ6wIGZWW9mPBSQD1OdHPiwIr'; // 예: vzrE...

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

  // [마이크 버튼 콜백]
  void _onMicButtonPressed() async {
    if (!_isRecording) {
      await _startRecording();
    } else {
      File? audioFile = await _stopRecording();
      if (audioFile != null) {
        // STT 연동: 네이버 API 호출
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

  // [메시지 전송 로직]
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
                // [마이크 버튼]
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
