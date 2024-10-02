import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'header.dart'; // Header 위젯을 import합니다.
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> exercisePlans = [];
  String? currentUserNickname;
  String? currentUserId; // 현재 사용자 ID 추가
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _initializeSocket();
  }

  void _initializeSocket() {
    SharedPreferences.getInstance().then((prefs) {
      final token = prefs.getString('token') ?? '';

      // Socket.IO 클라이언트 초기화
      socket = IO.io('http://localhost:8864', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {
          'token': token, // JWT 토큰을 쿼리 매개변수로 전달
        },
      });

      socket.connect();

      socket.onConnect((_) {
        print('Socket.IO에 연결되었습니다.');

        // 운동 계획 요청
        socket.emit('getExercisePlans', token); // 서버에 운동 계획 요청

        // 서버에서 exercisePlans 이벤트를 수신하여 데이터 업데이트
        socket.on('exercisePlansResponse', (data) {
          setState(() {
            if (data['success']) {
              exercisePlans = (data['plans'] as List).map((plan) {
                return {
                  'id': plan['_id'] ?? '',
                  'nickname': plan['nickname'] ?? '알 수 없는 사용자',
                  'selected_date': plan['selected_date'] ?? '알 수 없는 날짜',
                  'selected_exercise': plan['selected_exercise'] ?? '알 수 없는 운동',
                  'selected_participants': plan['selected_participants'] ?? '0',
                  'participants': plan['participants'] ?? [],
                  'selected_startTime': plan['selected_startTime'] ?? '알 수 없는 시작 시간',
                  'selected_endTime': plan['selected_endTime'] ?? '알 수 없는 종료 시간',
                  'selected_location': plan['selected_location'] ?? '알 수 없는 위치',
                  'profilePic': plan['profilePic'] ?? '',
                };
              }).toList();
            } else {
              print('운동 계획 로드 실패: ${data['message']}');
            }
          });
        });
      });

      socket.onDisconnect((_) {
        print('Socket.IO에 연결이 끊어졌습니다.');
      });
    });
  }


  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8864/api/users/userinfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentUserNickname = data['nickname']; // 로그인한 사용자의 닉네임 설정
          currentUserId = data['_id']; // 로그인한 사용자의 ID 설정
        });
      } else {
        print('사용자 정보를 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 정보를 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> _refresh() async {
    // Refresh logic (optional)
  }

  Future<void> _deleteExercisePlan(String planId) async {
    if (planId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제할 계획이 없습니다.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8864/api/users/planning/$planId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          exercisePlans.removeWhere((plan) => plan['id'] == planId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('운동 계획이 삭제되었습니다.')),
        );
      } else {
        print('운동 계획 삭제에 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('운동 계획 삭제 중 오류 발생: $e');
    }
  }

  Future<void> _participateInPlan(String currentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참여 요청을 보낼 수 없습니다.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8864/api/users/participate/$currentUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': currentUserId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = exercisePlans.indexWhere((plan) => plan['id'] == currentUserId);
          if (index != -1) {
            exercisePlans[index]['participants'].add(currentUserId); // 참가자 배열에 추가
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참여 요청이 성공적으로 전송되었습니다.')),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? '참여 요청 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('운동 계획 참여 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와의 연결에 문제가 발생했습니다.')),
      );
    }
  }

  void _confirmDelete(String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('삭제 확인', style: TextStyle(color: Colors.black)),
        content: Text('계획을 삭제하시겠습니까?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
            child: Text('아니요', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              _deleteExercisePlan(planId); // 삭제 요청
            },
            child: Text('예', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showParticipationDialog(String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('참여 확인', style: TextStyle(color: Colors.black)),
        content: Text('참여하시겠습니까?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
            child: Text('아니요', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              await _participateInPlan(planId); // 참여 요청 함수 호출
            },
            child: Text('예', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.dispose(); // Socket.IO 소켓 종료
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 전체 배경 색상 설정
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Header(), // Header 위젯 추가
            Expanded(
              child: ListView.builder(
                itemCount: exercisePlans.length,
                itemBuilder: (context, index) {
                  final plan = exercisePlans[index];
                  final isCurrentUserPlan = currentUserNickname == plan['nickname'];

                  // 현재 사용자 ID가 participants 배열에 포함되어 있는지 확인
                  if (plan['participants'].contains(currentUserId)) {
                    return SizedBox.shrink(); // 참여 중인 계획은 렌더링하지 않음
                  }

                  return Card(
                    color: Colors.grey[900], // 리스트 아이템 배경 색상 설정
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${plan['nickname']}님의 계획', // 수정된 부분
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isCurrentUserPlan) // 현재 사용자의 계획일 때만 삭제 버튼 표시
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(plan['id']);
                                  },
                                ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            '운동: ${plan['selected_exercise']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '날짜: ${plan['selected_date']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '시작 시간: ${plan['selected_startTime']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '종료 시간: ${plan['selected_endTime']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '장소: ${plan['selected_location']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '참여 인원: ${plan['participants'].length} / ${plan['selected_participants']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              _showParticipationDialog(plan['id']); // 참여 다이얼로그 표시
                            },
                            child: Text('참여하기'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
