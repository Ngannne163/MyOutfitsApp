import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_outfits/Screen/login_screen.dart';
import 'package:my_outfits/Screen/quiz_screen.dart';

import '../Screen/home_screen.dart';
import '../Screen/main_screen.dart';


class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<bool> checkFirstLogin(String uid) async{
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists){
      return doc.data()?['isFirstLogin']??true;
    }else{return true;}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: checkFirstLogin(user.uid),
            builder: (context, futureSnap) {
              if (futureSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (futureSnap.hasError) {
                return Center(child: Text('Có lỗi: ${futureSnap.error}'));
              }
              final isFirstLogin = futureSnap.data ?? true;
              if (isFirstLogin) {
                return const QuizScreen();
              } else {
                return const MainScreen();
              }
            },
          );
        }
      ),
    );
  }
}