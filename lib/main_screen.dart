import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'header.dart'; // Header 위젯을 import합니다.
import 'package:socket_io_client/socket_io_client.dart' as IO;
import './add_plan/existing_plan_screen.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late IO.Socket socket;
  List<Map<String, dynamic>> exercisePlans = [];
  String? currentUserNickname;
  String? currentUserId; // 현재 사용자 ID 추가
  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchExercisePlans(); // 운동 계획 가져오기 호출
    _initializeSocket();
  }
  void _initializeSocket() {
    socket = IO.io('http://localhost:8864', IO.OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .disableAutoConnect() // disable automatic connection
        .build());

    socket.connect(); // manually connect the socket

    socket.onConnect((_) {
      print('Connected to server');
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
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
          followers = data['followers'];
          following = data['following'];
        });
      } else {
        print('사용자 정보를 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 정보를 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> _fetchExercisePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8864/api/users/planinfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          exercisePlans = (data['plans'] as List).map((plan) {
            return {
              'id': plan['_id'] ?? '',
              'userId': plan['userId'] ?? '',
              'nickname': plan['nickname'] ?? '알 수 없는 사용자',
              'selected_date': plan['selected_date'] ?? '알 수 없는 날짜',
              'selected_exercise': plan['selected_exercise'] ?? '알 수 없는 운동',
              'selected_participants': plan['selected_participants'] ?? '0',
              'participants': plan['participants'] ?? [],
              'selected_startTime': plan['selected_startTime'] ?? '알 수 없는 시작 시간',
              'selected_endTime': plan['selected_endTime'] ?? '알 수 없는 종료 시간',
              'selected_location': plan['selected_location'] ?? '알 수 없는 위치',
              'profilePic': plan['profilePic'] ?? '',
              'isPrivate': plan['isPrivate'] ?? '',
            };
          }).toList();

          exercisePlans = exercisePlans.where((plan) {
            // isPrivate가 true일 경우 participants에 userId가 있는지 확인
            if (plan['isPrivate'] == true) {
              return plan['participants'].contains(currentUserId);
            }
            // isPrivate가 false일 경우 기존 조건 유지
            return following.contains(plan['userId']) || plan['userId'] == currentUserId;
          }).toList();

          isLoading = false;
        });
      }else {
        print('운동 계획을 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
        setState(() {
          isLoading = false; // 로딩 완료
        });
      }
    } catch (e) {
      print('운동 계획을 가져오는 중 오류 발생: $e');
      setState(() {
        isLoading = false; // 로딩 완료
      });
    }
  }

  Future<void> _refresh() async {
    // Refresh logic (optional)
    await _fetchExercisePlans(); // 운동 계획 새로 고침
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

  Future<void> _participateInPlan(String planId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty || currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참여 요청을 보낼 수 없습니다.')),
        );
      }
      return;
    }

    // 참여 요청을 Socket.IO를 통해 서버로 전송
    socket.emit('participateInPlan', {
      'planId': planId,
      'userId': currentUserId,
    });

    // 서버에서 참여 응답을 수신
    socket.on('participateResponse', (data) {
      if (mounted) {
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('참여 요청이 성공적으로 전송되었습니다.')),
          );
          setState(() {
            exercisePlans.removeWhere((plan) => plan['id'] == planId);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('참여 요청 실패: ${data['message']}')),
          );
        }
      }
    });
  }
  void _confirmDelete(String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('삭제 확인', style: TextStyle(color: Colors.white)),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // 전체 배경 색상 설정
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Header(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [ // Header 위젯 추가
            Expanded(
              child: isLoading // 로딩 중일 때 처리
                  ? Center(
                child: CircularProgressIndicator(), // 로딩 인디케이터
              )
                  : exercisePlans.where((plan) => !plan['participants'].contains(currentUserId)).isEmpty
                  ? Center(
                child: Text(
                  '현재 친구들의 계획이 없어요',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: exercisePlans.length,
                itemBuilder: (context, index) {
                  final plan = exercisePlans[index];

                  if (plan['participants'].contains(currentUserId)) {
                    return SizedBox.shrink(); // 아무것도 렌더링하지 않음
                  }
                  final isCurrentUserPlan = currentUserNickname == plan['nickname'];

                  // 현재 사용자 ID가 participants 배열에 포함되어 있는지 확인

                  return GestureDetector(
                    onTap: () {
                      // 운동 계획 ID와 함께 ExistingPlanScreen으로 이동
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ExistingPlanScreen(
                            planId: plan['id'], // planId를 전달
                            nickname: plan['nickname'], // nickname을 전달
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white, // 리스트 아이템 배경 색상 설정
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                      child: Padding(
                        padding: const EdgeInsets.all(35.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${plan['nickname']}님의 계획',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // isPrivate 값이 true일 때 자물쇠 아이콘과 텍스트 추가
                                    if (plan['isPrivate'] == true) ...[
                                      SizedBox(width: 5), // 아이콘과 텍스트 사이의 간격
                                      Icon(
                                        Icons.lock, // 자물쇠 아이콘
                                        color: Colors.green, // 초록색
                                        size: 15,
                                      ),
                                      SizedBox(width: 5), // 아이콘과 텍스트 사이의 간격
                                      Text(
                                        'private',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              '종류: ${plan['selected_exercise']}',
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '날짜: ${DateFormat('yyyy년 MM월 dd일').format(DateTime.parse(plan['selected_date']))}', // 날짜 형식 설정
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '시작 시간: ${plan['selected_startTime']}',
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '종료 시간: ${plan['selected_endTime']}',
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '장소: ${plan['selected_location']}',
                              style: TextStyle(color: Colors.black),
                            ),
                            Text(
                              '참여 인원: ${plan['participants'].length} / ${plan['selected_participants']}',
                              style: TextStyle(color: Colors.black),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // 본인이 아닌 경우에만 "참여하기" 버튼 표시
                                if (
                                !isCurrentUserPlan && plan['participants'].length < plan['selected_participants'])
                                  TextButton(
                                    onPressed: () => _showParticipationDialog(plan['id']), // 참여 요청 다이얼로그 호출
                                    child: Text('참여하기', style: TextStyle(color: Colors.blue)),
                                  ),
                                if(isCurrentUserPlan)
                                TextButton(
                                  onPressed: () => _confirmDelete(plan['id']), // 삭제 요청 다이얼로그 호출
                                  child: Text('삭제', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
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