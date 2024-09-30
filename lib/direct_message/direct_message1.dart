import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'direct_message2.dart'; // 직접 생성한 파일을 경로에 맞게 임포트하세요.

class DirectMessage1 extends StatefulWidget {
  @override
  _DirectMessage1State createState() => _DirectMessage1State();
}

class _DirectMessage1State extends State<DirectMessage1> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose(); // 텍스트 컨트롤러 해제
    super.dispose();
  }

  Future<void> _searchNickname() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:8864/api/users/search?nickname=$query'),
      headers: {
        'Authorization': 'Bearer $token', // 인증 헤더 추가
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      setState(() {
        _searchResults = responseData.map((item) {
          return {
            'nickname': item['nickname'] ?? '닉네임 없음',
            'id': item['_id'] ?? '아이디 없음',
            'isFollowing': item['isFollowing'] ?? false,
          };
        }).toList();
      });
    } else {
      print('검색 실패: ${response.statusCode}');
    }
  }

  void _navigateToDirectMessage2(String nickname, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectMessage2(
          nickname: nickname,
          userId: id,
          receiverId: id, // 여기에서 receiverId 추가
          initialMessages: [], // 초기 메시지 전달 (필요한 경우)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search nickname',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults.clear();
                  });
                },
              ),
            ),
            onSubmitted: (value) {
              _searchNickname(); // 검색 실행
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _searchResults.isEmpty
                ? Center(child: Text('검색 결과가 없습니다.'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_searchResults[index]['nickname']),
                  onTap: () {
                    _navigateToDirectMessage2(
                      _searchResults[index]['nickname'],
                      _searchResults[index]['id'],
                    );
                  },
                  trailing: ElevatedButton(
                    onPressed: () {
                      _followUser(_searchResults[index]['nickname'], index);
                    },
                    child: Text(
                      _searchResults[index]['isFollowing'] ? 'Unfollow' : 'Follow',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _followUser(String nickname, int index) async {
    // 팔로우 또는 언팔로우 요청 코드 작성
    // 예: http.post() 등을 사용하여 서버와 통신
    // 성공적으로 팔로우/언팔로우 후 _searchResults[index]['isFollowing'] 값을 반영
  }
}
