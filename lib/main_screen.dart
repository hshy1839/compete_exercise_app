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
  void didChangeDependencies() {
    super.didChangeDependencies();
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
              'planTitle': plan['planTitle'] ?? '',
            };
          }).toList();


          exercisePlans = exercisePlans.where((plan) {
            if (plan['userId'] == currentUserId) {
              return true;
            }
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
  String _calculateDDay(String dateString) {
    DateTime selectedDate = DateTime.parse(dateString);
    DateTime today = DateTime.now();

    // D-Day 계산
    int dDay = selectedDate.difference(today).inDays;

    if (dDay > 0) {
      return 'D-$dDay'; // 미래의 계획
    } else if (dDay == 0) {
      return 'D-Day'; // 오늘
    } else {
      return 'D+${-dDay}'; // 과거의 계획
    }
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
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Header(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(),
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
                  final plan = exercisePlans[exercisePlans.length - 1 - index];

                  if (plan['participants'].contains(currentUserId)) {
                    return SizedBox.shrink();
                  }
                  final isCurrentUserPlan = currentUserNickname == plan['nickname'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ExistingPlanScreen(
                            planId: plan['id'],
                            nickname: plan['nickname'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(
                            color: Colors.blue,
                            width: 5,
                          ),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${DateFormat('yyyy.MM.dd').format(DateTime.parse(plan['selected_date']))}',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      _calculateDDay(plan['selected_date']),
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (plan['isPrivate'] == true) ...[
                                  Row(
                                    children: [
                                      SizedBox(width: 5),
                                      Icon(
                                        Icons.lock,
                                        color: Colors.green,
                                        size: 15,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'private',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${plan['planTitle']}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${plan['nickname']} 님의 계획',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      ' ${plan['participants'].length} / ${plan['selected_participants']}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                                // 본인이 아닌 경우에만 "참여하기" 버튼 표시
                                if (!isCurrentUserPlan && plan['participants'].length < plan['selected_participants'])
                                  IconButton(
                                    onPressed: () => _showParticipationDialog(plan['id']),
                                    icon: Icon(
                                      Icons.exit_to_app,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                  ),
                                if (isCurrentUserPlan)
                                  TextButton(
                                    onPressed: () => _confirmDelete(plan['id']),
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