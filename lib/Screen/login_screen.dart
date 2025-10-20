import 'package:flutter/material.dart';
import 'package:my_outfits/data/firebase_servise/firebase_auth.dart';
import 'package:my_outfits/routes/app_routes.dart';
import 'package:my_outfits/util/custom_textfield.dart';
import 'package:my_outfits/util/dialog.dart';
import 'package:my_outfits/util/exception.dart';

import '../util/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  FocusNode emailFocus = FocusNode();
  final password = TextEditingController();
  FocusNode passFocus = FocusNode();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Authentication().login(email: email.text, password: password.text);
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

  @override
  Widget build(BuildContext) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003153), Color(0xFFE7A4B8)],
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

              const SizedBox(height: 50),

              Container(
                width: double.infinity,
                height: 350,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(180),
                    bottomRight: Radius.circular(30),
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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

                    CustomButton(
                      onTap: _handleLogin,
                      isLoading: _isLoading,
                      text: 'Đăng nhập',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                height: 200,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(150),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'HOẶC',
                      style: TextStyle(fontSize: 17, color: Color(0xFF5C5C5C)),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Đăng nhập với',
                      style: TextStyle(fontSize: 17, color: Color(0xFF5C5C5C)),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Google()],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Không có tài khoản?',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ClickHere(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Các Widget
  Widget Google() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () async {
          try {
            await Authentication().signInWithGoogle();
          } on exceptions catch (e) {
            dialogBuilder(context, e.message);
          }
        },
        child: Image.asset(
          'assets/image/logo_google.png',
          height: 100,
          width: 100,
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
          Navigator.pushNamed(context, AppRoutes.signup);
        },
        child: Text(
          'Bấm vào đây.',
          style: TextStyle(
            fontSize: 17,
            color: Color (0xC0FFEBBE),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
