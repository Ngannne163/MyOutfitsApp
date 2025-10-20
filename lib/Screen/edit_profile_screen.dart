import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/firebase_servise/firestore.dart';
import '../data/firebase_servise/storage.dart';
import '../data/view_model/profile_view_model.dart';
import '../util/custom_button.dart';
import '../util/custom_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  File? _selectedImage;
  bool _isSaving = false;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _nicknameFocus = FocusNode();

  final StorageMethod _storage = StorageMethod();
  final Firebase_Firestore _firestore = Firebase_Firestore();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _nicknameController = TextEditingController();

    _nameFocus.addListener(() => setState(() {}));
    _nicknameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _nameFocus.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  void _setInitialData(ProfileViewModel viewModel) {
    if (viewModel.user != null) {
      /// Chỉ set nếu controller trống (ngăn chặn mất dữ liệu khi rebuild)
      if (_emailController.text.isEmpty) {
        _emailController.text = viewModel.user!.email ?? '';
        _nameController.text = viewModel.user!.username ?? '';
        _nicknameController.text = viewModel.user!.nickname ?? '';
      }
    }
  }

  /// --- Logic Xử lý Ảnh ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// --- Logic Lưu Dữ liệu ---
  Future<void> _saveProfile(BuildContext context, ProfileViewModel viewModel) async {
    /// ... (Logic kiểm tra tên giữ nguyên)
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên người dùng không được để trống!')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    String newProfileUrl = viewModel.user?.profile ?? '';

    try {
      /// 1. Upload ảnh đại diện nếu có thay đổi
      if (_selectedImage != null) {
        newProfileUrl = await _storage.uploadImageToStorage('profile_avatar', _selectedImage!);
      }

      /// 2. Cập nhật dữ liệu người dùng trong Firestore
      await _firestore.updateProfileData(
        username: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        profileUrl: newProfileUrl,
      );

      /// Thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
      );

      /// Quay lại màn hình trước
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu hồ sơ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileViewModel>(context);
    const Color backgroundColor = Color(0xFFF8F8FF);

    if (viewModel.user!= null) {
      _setInitialData(viewModel);
    }

    final currentProfileUrl = viewModel.user?.profile;

    if (viewModel.isLoading && viewModel.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa trang cá nhân',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold,),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            /// Khu vực Ảnh đại diện
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (currentProfileUrl?.isNotEmpty ?? false)
                    ? NetworkImage(currentProfileUrl!)
                    : null as ImageProvider?,
                child: (_selectedImage == null && (currentProfileUrl == null || currentProfileUrl.isEmpty))
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickImage,
              child: const Text(
                'Đổi ảnh đại diện',
                style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 40),

            _buildTextField(
              controller: _emailController,
              icon: Icons.email_outlined,
              hintText: 'Email',
              enabled: false,
            ),
            const SizedBox(height: 24),


            CustomTextField(
              controller: _nameController,
              icon: Icons.person_outline,
              hintText: 'Name',
              focusNode: _nameFocus,
            ),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _nicknameController,
              icon: Icons.person_pin_outlined,
              hintText: 'Nickname',
              focusNode: _nicknameFocus,
            ),

            const SizedBox(height: 80),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: CustomButton(
                onTap: ()=> _saveProfile(context, viewModel),
                text: 'Lưu',
                isLoading: _isSaving,
                backgroundColor: Colors.grey.shade300,
                textColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget riêng cho Email
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(fontSize: 18, color: enabled ? Colors.black : Colors.grey),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: enabled ? const Color(0xFF5C5C5C) : Colors.grey),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black45),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}