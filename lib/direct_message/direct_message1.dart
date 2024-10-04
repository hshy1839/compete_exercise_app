import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'direct_message2.dart'; // DirectMessage2를 임포트하세요.
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';
import '../socket_service.dart';

class DirectMessage1 extends StatefulWidget {
  @override
  _DirectMessage1State createState() => _DirectMessage1State();
}

class _DirectMessage1State extends State<DirectMessage1> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  String _nickname = ''; // _nickname 속성 추가
  String _userId = ''; // 유저 ID를 저장할 변수 추가
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.connect();

    // 소켓 이벤트 리스너를 설정
    socketService.on('chatRoomCreated', _onChatRoomCreated);
  }

  // 이벤트 핸들러 메서드로 분리
  void _onChatRoomCreated(data) {
    if (!mounted) return;

    String chatRoomId = data['chatRoomId'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectMessage2(
          chatRoomId: chatRoomId,
          userId: _userId,
          receiverId: data['receiverId'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.off('chatRoomCreated', _onChatRoomCreated); // 이벤트 해제
    _searchController.dispose();
    super.dispose();
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
      final Map<String, dynamic> userData = jsonDecode(response.body);

      if (userData['success']) {
        if (mounted) {
          setState(() {
            _nickname = userData['nickname'] ?? 'Unknown'; // 기본값 제공
          });
        }
      } else {
        print('사용자 정보 조회 실패: ${userData['message']}');
      }
    } else {
      print('사용자 정보 조회 실패: ${response.statusCode}');
    }
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
      if (mounted) {
        setState(() {
          _searchResults = responseData.map((item) {
            return {
              'nickname': item['nickname'] ?? '닉네임 없음',
              'id': item['_id'] ?? '아이디 없음', // ID를 사용
            };
          }).toList();
        });
      }
    } else {
      print('검색 실패: ${response.statusCode}');
    }
  }

  Future<String?> _getUserIdByNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:8864/api/users/search?nickname=$nickname'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> userData = jsonDecode(response.body);
      if (userData.isNotEmpty) {
        return userData[0]['_id']; // 첫 번째 사용자 ID 반환
      } else {
        print('사용자 ID를 찾을 수 없습니다.');
      }
    } else {
      print('ID 조회 실패: ${response.statusCode}');
    }
    return null; // ID를 찾지 못한 경우 null 반환
  }

  void _navigateToDirectMessage2(String receiverId) async {
    String? userId = await _getUserIdByNickname(_nickname);
    print('userId: $userId, receiverId: $receiverId');

    if (userId != null && receiverId.isNotEmpty) {
      final socketService = Provider.of<SocketService>(context, listen: false);

      socketService.off('chatRoomCreated');
      // 소켓으로 채팅방 생성 요청
      socketService.emit('createChatRoom', {'senderId': userId, 'receiverId': receiverId});

      socketService.on('chatRoomCreated', (data) {
        String chatRoomId = data['chatRoomId'];
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DirectMessage2(
                chatRoomId: chatRoomId,
                userId: userId,
                receiverId: receiverId,
              ),
            ),
          );
        }
      });
    } else {
      print('유효하지 않은 ID: userId: $userId, receiverId: $receiverId');
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
                    // 닉네임 클릭 시 DirectMessage2로 이동
                    _navigateToDirectMessage2(
                      _searchResults[index]['id'], // receiverId
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}