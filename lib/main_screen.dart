import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'header.dart'; // Header 위젯을 import합니다.

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> exercisePlans = [];
  String? currentUserNickname;
  String? currentUserId; // 현재 사용자 ID 추가

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchExercisePlans();
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

  Future<void> _fetchExercisePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8864/api/users/planinfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final plans = data['plans'] as List;

        setState(() {
          exercisePlans = plans.map((plan) {
            return {
              'id': plan['_id'] ?? '',
              // 계획 ID 추가
              'nickname': plan['nickname'] ?? '알 수 없는 사용자',
              'selected_date': plan['selected_date'] ?? '알 수 없는 날짜',
              'selected_exercise': plan['selected_exercise'] ?? '알 수 없는 운동',
              'selected_participants': plan['selected_participants'] ?? '0',
              // 참가자 수 초기화
              'participants': plan['participants'] ?? [],
              // 참가자 배열 추가
              'selected_startTime': plan['selected_startTime'] ??
                  '알 수 없는 시작 시간',
              'selected_endTime': plan['selected_endTime'] ?? '알 수 없는 종료 시간',
              'selected_location': plan['selected_location'] ?? '알 수 없는 위치',
              'profilePic': plan['profilePic'] ?? '',
              // 프로필 사진 추가
            };
          }).toList();
        });
      } else {
        print('운동 계획을 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
        print('응답 본문: ${response.body}');
      }
    } catch (e) {
      print('운동 계획을 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> _refresh() async {
    await _fetchExercisePlans();
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
        print('응답 본문: ${response.body}');
      }
    } catch (e) {
      print('운동 계획 삭제 중 오류 발생: $e');
    }
  }

  Future<void> _participateInPlan(String currentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Token, planId 및 currentUserId의 유효성 검사
    if (token == null || token.isEmpty || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참여 요청을 보낼 수 없습니다.')),
      );
      return;
    }

    try {
      print(
          "Sending participation request for planId: $currentUserId, userId: $currentUserId"); // 디버깅 로그 추가
      final response = await http.post(
        Uri.parse('http://localhost:8864/api/users/participate/$currentUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': currentUserId, // 현재 사용자 ID를 요청 본문에 포함
        }),
      );

      print("Response status: ${response.statusCode}"); // 응답 상태 코드 로그 추가
      if (response.statusCode == 200) {
        setState(() {
          final index = exercisePlans.indexWhere((plan) =>
          plan['id'] == currentUserId);
          if (index != -1) {
            exercisePlans[index]['selected_participants'] += 1; // 참가자 수 증가
            exercisePlans[index]['participants'].add(
                currentUserId); // 참가자 배열에 추가
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참여 요청이 성공적으로 전송되었습니다.')),
        );
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? '참여 요청 실패';
        print('운동 계획 참여에 실패했습니다. 상태 코드: ${response
            .statusCode}, 메시지: $errorMessage');
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
      builder: (context) =>
          AlertDialog(
            title: Text('삭제 확인', style: TextStyle(color: Colors.black)),
            // 텍스트 색상 검은색으로 변경
            content: Text(
                '계획을 삭제하시겠습니까?', style: TextStyle(color: Colors.black)),
            // 텍스트 색상 검은색으로 변경
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
                child: Text('아니요',
                    style: TextStyle(color: Colors.black)), // 텍스트 색상 검은색으로 변경
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  _deleteExercisePlan(planId); // 삭제 요청
                },
                child: Text('예',
                    style: TextStyle(color: Colors.black)), // 텍스트 색상 검은색으로 변경
              ),
            ],
          ),
    );
  }

  void _showParticipationDialog(String planId) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('참여 확인', style: TextStyle(color: Colors.black)),
            // 텍스트 색상 검은색으로 변경
            content: Text('참여하시겠습니까?', style: TextStyle(color: Colors.black)),
            // 텍스트 색상 검은색으로 변경
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
                child: Text('아니요',
                    style: TextStyle(color: Colors.black)), // 텍스트 색상 검은색으로 변경
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  await _participateInPlan(planId); // 참여 요청 함수 호출
                },
                child: Text('예',
                    style: TextStyle(color: Colors.black)), // 텍스트 색상 검은색으로 변경
              ),
            ],
          ),
    );
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
                  final isCurrentUserPlan = currentUserNickname ==
                      plan['nickname'];

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
                              if (isCurrentUserPlan) // 현재 사용자가 계획 생성자인 경우 삭제 버튼 표시
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(plan['id']),
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
                            '참가자 수: ${plan['selected_participants']}',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (!plan['participants'].contains(
                                  currentUserId)) {
                                _showParticipationDialog(plan['id']);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('이미 참여하고 있는 계획입니다.')),
                                );
                              }
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
