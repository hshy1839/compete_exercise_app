import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'direct_message2.dart'; // DirectMessage2를 임포트하세요.
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DirectMessage1 extends StatefulWidget {
  @override
  _DirectMessage1State createState() => _DirectMessage1State();
}

class _DirectMessage1State extends State<DirectMessage1> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  String _nickname = ''; // _nickname 속성 추가
  String _userId = ''; // 유저 ID를 저장할 변수 추가
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchUserInfo(); // 사용자 정보 조회
  }

  void _initializeSocket() {
    // Socket.IO 초기화
    socket = IO.io('http://localhost:8864', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false, // 필요시 자동 연결 비활성화
    });

    socket!.connect(); // 소켓 연결
    socket!.on('connect', (_) {
      print('Socket connected: ${socket!.id}');
    });

    socket!.on('disconnect', (_) {
      print('Socket disconnected');
    });

    socket!.on('connect_error', (data) {
      print('Socket connection error: $data');
    });
  }
  @override
  void dispose() {
    _searchController.dispose(); // 텍스트 컨트롤러 해제
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
        setState(() {
          _nickname = userData['nickname'] ?? 'Unknown'; // 기본값 제공
        });
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
      setState(() {
        _searchResults = responseData.map((item) {
          return {
            'nickname': item['nickname'] ?? '닉네임 없음',
            'id': item['_id'] ?? '아이디 없음', // ID를 사용
          };
        }).toList();
      });
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
    String? userId = await _getUserIdByNickname(_nickname); // 닉네임으로 사용자 ID 조회
    print('userId: $userId, receiverId: $receiverId');

    if (userId != null && receiverId.isNotEmpty) {
      // Socket.IO로 채팅방 생성 요청
      socket?.emit('createChatRoom', {'senderId': userId, 'receiverId': receiverId});

      socket?.on('chatRoomCreated', (data) {
        String chatRoomId = data['chatRoomId']; // 서버로부터 받은 채팅방 ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DirectMessage2(
              chatRoomId: chatRoomId, // 생성된 채팅방 ID 전달
              userId: userId, // 내 ID 전달
              receiverId: receiverId, // 상대방 ID 전달
            ),
          ),
        );
      });
    } else {
      // 오류 처리: ID가 비어있는 경우
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
