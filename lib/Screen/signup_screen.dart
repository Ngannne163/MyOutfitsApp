import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_outfits/data/firebase_servise/firebase_auth.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:my_outfits/util/custom_button.dart';
import 'package:my_outfits/util/custom_textfield.dart';
import 'package:my_outfits/util/dialog.dart';
import 'package:my_outfits/util/exception.dart';
import '../util/imagepicker.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreen();
}

class _SignUpScreen extends State<SignUpScreen> {
  final email = TextEditingController();
  FocusNode emailFocus = FocusNode();
  final password = TextEditingController();
  FocusNode passFocus = FocusNode();
  final confirm = TextEditingController();
  FocusNode confirmFocus = FocusNode();
  final username = TextEditingController();
  FocusNode usernameFocus = FocusNode();
  File? _imageFile;
  bool _isLoading = false;
  bool _isPickingImage = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    username.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    confirmFocus.dispose();
    usernameFocus.dispose();
    super.dispose();
  }

  /// sign up
  Future<void> _handleSignUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Authentication().SignUp(
        email: email.text,
        password: password.text,
        confirm: confirm.text,
        username: username.text,
        profile: _imageFile,
      );
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.mainpage);
    } on exceptions catch (e) {
      dialogBuilder(context, e.message);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleImagePick() async {
    setState(() {
      _isPickingImage = true;
    });
    try {
      /// Sử dụng ImagePickerr đã được sửa để trả về File?
      final imageFile = await ImagePickerr().uploadImage('gallery');
      setState(() {
        _imageFile = imageFile;
      });
    } on Exception catch (e) {
      dialogBuilder(context, 'Lỗi khi chọn ảnh: $e');
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE7A4B8), Color(0xFF003153)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'My Outfits',
                style: TextStyle(
                  fontFamily: 'KaushanScript',
                  fontSize: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: _isPickingImage ? null : _handleImagePick,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey,
                  child: _isPickingImage
                      ? const CircularProgressIndicator(color: Colors.white)
                      : CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider<Object>?
                        : const AssetImage('assets/image/person.png'),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                height: 500,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(30),
                ),

                child: Column(
                  children: [
                    CustomTextField(
                      controller: email,
                      icon: Icons.email,
                      hintText: 'Email',
                      focusNode: emailFocus,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: password,
                      icon: Icons.lock,
                      hintText: 'Password',
                      focusNode: passFocus,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: confirm,
                      icon: Icons.lock_open,
                      hintText: 'Confirm password',
                      focusNode: confirmFocus,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: username,
                      icon: Icons.person,
                      hintText: 'Username',
                      focusNode: usernameFocus,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      onTap: _handleSignUp,
                      isLoading: _isLoading,
                      text: "Đăng ký",
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Đã có tài khoản?',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ClickHere(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClickHere extends StatelessWidget {
  const ClickHere({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.login);
        },
        child: Text(
          'Bấm vào đây.',
          style: TextStyle(
            fontSize: 17,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
