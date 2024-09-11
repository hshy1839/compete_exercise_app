import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../header.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nickname = 'Loading...';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.edit_document),
                        onPressed: _navigateToEditProfile,
                        iconSize: 15, // 아이콘 크기
                        padding: EdgeInsets.zero, // 패딩 제거
                        constraints: BoxConstraints(), // 제약 조건 제거
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
                    '12', // 하드코딩된 게시물 수
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Posts'),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    '10k', // 하드코딩된 팔로워 수
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Followers'),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    '180', // 하드코딩된 팔로잉 수
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Following'),
                ],
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
