import 'dart:io';

// ✅ edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _likesController = TextEditingController();
  final _dislikesController = TextEditingController();
  int? _age;
  String? _gender;

  File? _imageFile;
  String? _existingImageUrl;

  bool _isLoading = false;

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      _nicknameController.text = data['nickname'] ?? '';
      _nameController.text = data['name'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _likesController.text = data['likes'] ?? '';
      _dislikesController.text = data['dislikes'] ?? '';
      _age = data['age'];
      _gender = data['gender'];
      _existingImageUrl = data['profileImage'];
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;
    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final imageUrl = await _uploadImage(uid);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'nickname': _nicknameController.text.trim(),
      'name': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'likes': _likesController.text.trim(),
      'dislikes': _dislikesController.text.trim(),
      'age': _age,
      'gender': _gender,
      if (imageUrl != null) 'profileImage': imageUrl,
    });

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 저장되었습니다.')),
    );

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("프로필 수정"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
            tooltip: "저장",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_existingImageUrl != null
                      ? NetworkImage(_existingImageUrl!)
                      : const AssetImage('assets/users/profile1.jpg')) as ImageProvider,
                ),
              ),
              const SizedBox(height: 8),
              const Text('사진을 탭하여 변경'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임'),
              ),
              const SizedBox(height: 12),
              Text("이메일: $email", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: '한 줄 소개'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _age,
                items: List.generate(100, (i) => i + 1)
                    .map((age) => DropdownMenuItem(value: age, child: Text("$age")))
                    .toList(),
                onChanged: (val) => setState(() => _age = val),
                decoration: const InputDecoration(labelText: '나이'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                items: const ["남", "여"]
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gender = val),
                decoration: const InputDecoration(labelText: '성별'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _likesController,
                decoration: const InputDecoration(labelText: '좋아하는 음식'),
              ),
              TextFormField(
                controller: _dislikesController,
                decoration: const InputDecoration(labelText: '싫어하는 것'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
