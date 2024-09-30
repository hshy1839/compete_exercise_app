import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../header.dart';
import '../socket_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nickname = 'Loading...';
  int _postCount = 0; // 게시물 수
  int _followersCount = 0; // 팔로워 수
  int _followingCount = 0; // 팔로잉 수

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:8864/api/users/userinfo'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        _nickname = responseData['nickname'] ?? 'Unknown User';
        _postCount = responseData['postCount'] ?? 0; // 게시물 수
        _followersCount = responseData['followersCount'] ?? 0; // 팔로워 수
        _followingCount = responseData['followingCount'] ?? 0; // 팔로잉 수
      });
    } else {
      setState(() {
        _nickname = 'Error fetching user info';
      });
    }
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, '/edit_profile'); // 프로필 수정 페이지로 이동
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // 로그아웃 처리
    await prefs.remove('token'); // JWT 삭제

    // 소켓 연결 해제
    SocketService().disconnect();
    print('소켓 연결 해제됨'); // 소켓 해제 로그 출력

    Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Header(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 70,
                color: Colors.grey[600],
              ),
              SizedBox(width: 20), // 아이콘 우측 마진
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _nickname,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    _postCount.toString(), // 게시물 수
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text('Posts',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    _followersCount.toString(), // 팔로워 수
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text('Followers',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    _followingCount.toString(), // 팔로잉 수
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text('Following',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          // 프로필 수정 및 로그아웃 버튼 추가
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: ElevatedButton(
                  onPressed: _navigateToEditProfile,
                  child: Text('Edit Profile',
                    style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // 버튼 배경 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // 사각형 버튼의 모서리 반경
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0), // 버튼의 상하 패딩
                  ),
                ),
              ),
              SizedBox(width: 20), // 버튼 사이 마진
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  child: Text('Logout',
                    style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // 버튼 배경 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0), // 사각형 버튼의 모서리 반경
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0), // 버튼의 상하 패딩
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // 게시물 추가 영역을 여기에 배치할 수 있습니다.
        ],
      ),
    );
  }
}
