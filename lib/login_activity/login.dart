import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO; // Socket.IO 패키지 추가
import '../header.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late IO.Socket socket; // 소켓 변수 추가

  @override
  void initState() {
    super.initState();
    // 소켓 초기화
    socket = IO.io('http://localhost:8864', {
      'transports': ['websocket'],
      'autoConnect': false,
    });
  }

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
      final token = responseData['token'] ?? '';

      if (loginSuccess) {
        // 로그인 성공 시 SharedPreferences에 JWT 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('isLoggedIn', true); // 로그인 상태 플래그 저장

        // 로그인 성공 시 소켓 연결
        _initSocket();

        // 로그인 성공 다이얼로그 표시
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('로그인', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            content: Text('환영합니다'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // 모서리 반경을 0으로 설정
            ),
            actions: [
              TextButton(
                child: Text('확인', style: TextStyle( color: Colors.blueAccent)),
                onPressed: () {
                  // 메인 화면으로 이동하고 이전 모든 화면 제거
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
              ),
            ],
          ),
        );
      } else {
        // 로그인 실패
        _showErrorDialog(responseData['message'] ?? 'Error: 500');
      }
    } else {
      // 로그인 실패
      _showErrorDialog('로그인 실패. 아이디와 비밀번호를 확인해 주세요.');
    }
  }

  void _initSocket() {
    socket.connect(); // 서버에 소켓 연결
    socket.onConnect((_) {
      print('소켓 연결됨');
      // 여기에 소켓 이벤트 핸들링 로직 추가 가능
    });
    socket.onDisconnect((_) {
      print('소켓 연결 해제됨');
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그인 실패', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 모서리 반경을 0으로 설정
        ),
        actions: [
          TextButton(
            child: Text('확인', style: TextStyle( color: Colors.blueAccent)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {

    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // 중앙 정렬을 시작으로 변경
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 여기에 주어진 Text 위젯들을 최상단으로 이동
            SizedBox(height: 150),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // With Me 문구를 대체할 이미지 위젯
                Image.asset(
                  'assets/images/app_logo.png', // 이미지 경로
                  height: 50, // 이미지 높이 조절 (필요에 따라 조정)
                ),
                SizedBox(height: 30),
                Text(
                  '함께하는 모든 순간 ,',
                  style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 0),
                Text(
                  '손 끝에서 시작되는 약속',
                  style: TextStyle(color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // 문구 아래의 공간을 줄여서 텍스트 필드가 더 위에 나타나도록 설정
            SizedBox(height: 100), // 필요에 따라 조정
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: '아이디',
                labelStyle: TextStyle(color: Colors.grey), // 기본 라벨 색상
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2), // 클릭 시 테두리 색상을 회색으로 변경
                ),
                floatingLabelStyle: TextStyle(color: Colors.grey), // 포커스 시 라벨 색상을 회색으로 변경
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 2), // 클릭 시 테두리 색상을 회색으로 변경
                ),
                floatingLabelStyle: TextStyle(color: Colors.grey), // 포커스 시 라벨 색상을 회색으로 변경
              ),
            ),
            SizedBox(height: 20),
            // ElevatedButton 위젯 수정
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF25c387), // 버튼 배경색을 #25c387로 설정
                minimumSize: Size(double.infinity, 56), // 텍스트 필드와 같은 너비와 높이로 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 모서리 반경을 0으로 설정
                ),
              ),
              child: Text('로그인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)), // 텍스트 색상을 흰색으로 설정
            ),

            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // 버튼 배경색을 #25c387로 설정
                minimumSize: Size(double.infinity, 56), // 텍스트 필드와 같은 너비와 높이로 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 모서리 반경을 0으로 설정
                ),
              ),
              child: Text('회원가입', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

}
