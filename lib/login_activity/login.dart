import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // 로그인 요청을 보낼 URL
    final url = Uri.parse('http://localhost:8864/api/users/login');

    // POST 요청을 보내기 위한 데이터
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    // 서버 응답 확인
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // 서버 응답 데이터에서 필요한 값 추출 (null 체크 추가)
      final loginSuccess = responseData['loginSuccess'] ?? false;
      final userId = responseData['userId'] ?? '';
      final token = responseData['token'] ?? '';

      if (loginSuccess) {
        // 로그인 성공 시 SharedPreferences에 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('token', token); // 서버에서 반환한 토큰을 저장
        await prefs.setBool('isLoggedIn', true); // 로그인 상태 플래그 저장

        // 로그인 성공 후 메인 화면으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        // 로그인 실패
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('실패'),
            content: Text(responseData['message'] ?? '로그인 실패. 아이디와 비밀번호를 확인해 주세요.'),
            actions: [
              TextButton(
                child: Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } else {
      // 로그인 실패
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('실패'),
          content: Text('로그인 실패. 아이디와 비밀번호를 확인해 주세요.'),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('로그인'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup1');
              },
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
