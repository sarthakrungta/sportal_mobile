import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loginFail = false;
  String _email = "";
  bool _isLoading = false;
  Map<String, dynamic> _clubData = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _fetchClubData(String email) async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });

    try {
      final response = await http.get(Uri.parse(
          'https://sportal-backend.onrender.com/get-club-info/$email'));

      if (response.statusCode == 200) {
        setState(() {
          _clubData = jsonDecode(response.body);
        });
        _saveEmail();
        Navigator.pushNamed(
          context,
          '/template',
          arguments: {
            'email': email,
            'clubData': _clubData,
          },
        );
      } else {
        setState(() {
          _loginFail = true;
        });
      }
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');

    if (savedEmail != null && savedEmail.contains('@')) {
      await _fetchClubData(savedEmail);
    }
  }

  Future<void> _saveEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    if (savedEmail == null) {
      await prefs.setString('email', _email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(249, 253, 254, 1),
      resizeToAvoidBottomInset:
          true, // Ensure that the screen resizes when the keyboard opens
      body: _isLoading // Show loading indicator
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              reverse: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 100),
                    _buildHeader(),
                    const SizedBox(height: 350),
                    _buildTextField(
                      label: "Email",
                      hintText: "",
                      onChanged: (value) {
                        _email = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_loginFail) _buildLoginFailNotification(),
                    _buildLoginButton(),
                    const SizedBox(
                      height: 5,
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'Welcome',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Please enter your data to continue',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required String label,
      required String hintText,
      bool obscureText = false,
      Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.deepPurpleAccent, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFailNotification() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Text(
        'Login Failed',
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 15.0,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_email.isNotEmpty) {
          await _fetchClubData(_email);
        } else {
          setState(() {
            _loginFail = true;
          });
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color.fromRGBO(60, 17, 185, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Login',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
