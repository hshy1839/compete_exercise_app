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
      body: Column(
        children: [
          // 사용자 정의 Header 위젯을 상단에 배치
          Header(),
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
