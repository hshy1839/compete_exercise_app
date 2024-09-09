import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'header.dart'; // Header 위젯을 import합니다.

class MainScreen extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // 로그아웃 처리

    Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
        // 헤더 관련 코드가 있을 경우 추가
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text('Main Screen Content'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
