import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_outfits/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(
        context, AppRoutes.mainpage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003153), Color(0xFFE7A4B8)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            const SizedBox(height: 0),

            const Text(
              'My\nOutfits',
              style: TextStyle(
                fontFamily: 'KaushanScript',
                fontSize: 70,
                color: Colors.white,
              ),
            ),

            const Text(
              'WELCOME',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0XFF3E3E3E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
