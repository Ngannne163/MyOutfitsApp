import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;


  const CustomButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.textColor = Colors.white,
    this.isLoading = false,
    this.backgroundColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading? null : onTap,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
        ? const CircularProgressIndicator(color: Colors.white)
        : Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 22
          ),
        ),
      )
    );
  }
}
