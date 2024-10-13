import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.deepPurple, // Adjust background color if needed
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers the content vertically
            children: [
              Image.asset('assets/images/splash.png'), // Display your image
              const SizedBox(height: 5), // Add spacing between image and text
              const Text(
                'Post More, Stress Less',
                style: TextStyle(
                  color: Colors.white, // Change the text color as needed
                  fontSize: 24, // Adjust the font size
                  fontWeight: FontWeight.bold, // Optional: make the text bold
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
