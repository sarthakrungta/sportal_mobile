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
        color: const Color.fromRGBO(60, 17, 185, 1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers the content vertically
            children: [
              Image.asset('assets/images/splash.png'), // Display your image
            ],
          ),
        ),
      ),
    );
  }
}
