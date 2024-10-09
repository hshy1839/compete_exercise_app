import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  // 서버로 검색어 전송 및 결과 가져오기
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
            'nickname': item['nickname'] ?? '닉네임 없음', // 기본값 설정
            'id': item['_id'] ?? '아이디 없음', // _id로 수정
            'isFollowing': item['isFollowing'] ?? false // 팔로우 상태 서버에서 가져오기
          };
        }).toList();
      });
    } else {
      print('검색 실패: ${response.statusCode}');
    }
  }

  // 팔로우 및 팔로우 취소 요청
  Future<void> _toggleFollowUser(String nickname, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // 현재 팔로우 상태에 따라 API 요청 분기
    final isFollowing = _searchResults[index]['isFollowing'];
    final url = isFollowing
        ? 'http://localhost:8864/api/users/deletefollow' // 팔로우 취소
        : 'http://localhost:8864/api/users/follow'; // 팔로우

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nickname': nickname}), // 닉네임 사용
    );

    if (response.statusCode == 200) {
      // 성공적인 팔로우/팔로우 취소 처리
      setState(() {
        _searchResults[index]['isFollowing'] = !_searchResults[index]['isFollowing']; // 팔로우 상태 토글
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFollowing ? '팔로우 취소 성공' : '팔로우 성공')),
      );
    } else {
      // 오류 처리
      print('Error: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 실패: ${response.body}')),
      );
    }
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
              hintText: '닉네임 검색',
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
      body: _searchResults.isEmpty
          ? Center(child: Text('검색 결과가 없습니다.'))
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_searchResults[index]['nickname']),
            trailing: ElevatedButton(
              onPressed: () {
                _toggleFollowUser(_searchResults[index]['nickname'], index); // 팔로우 토글
              },
              child: Text(_searchResults[index]['isFollowing'] ? '팔로우 취소' : '팔로우'), // 팔로우 상태에 따라 텍스트 변경
            ),
          );
        },
      ),
    );
  }
}
