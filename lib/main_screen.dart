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
        });
      } else {
        print('Failed to load user info. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user info: $e');
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
              'id': plan['_id'] ?? '', // 계획 ID 추가
              'nickname': plan['nickname'] ?? 'Unknown User',
              'selected_date': plan['selected_date'] ?? 'Unknown Date',
              'selected_exercise': plan['selected_exercise'] ?? 'Unknown Exercise',
              'selected_participants': plan['selected_participants'] ?? 'Unknown Participants',
              'selected_startTime': plan['selected_startTime'] ?? 'Unknown Start Time',
              'selected_endTime': plan['selected_endTime'] ?? 'Unknown End Time',
              'selected_location': plan['selected_location'] ?? 'Unknown Location',
              'profilePic': plan['profilePic'] ?? '', // 프로필 사진 추가
            };
          }).toList();
        });
      } else {
        print('Failed to load exercise plans. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching exercise plans: $e');
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
        print('Failed to delete exercise plan. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error deleting exercise plan: $e');
    }
  }

  void _confirmDelete(String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('삭제 확인', style: TextStyle(color: Colors.white)),
        content: Text('계획을 삭제하시겠습니까?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
            },
            child: Text('아니요', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              _deleteExercisePlan(planId); // 삭제 요청
            },
            child: Text('예', style: TextStyle(color: Colors.white)),
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
                  final isCurrentUserPlan = currentUserNickname == plan['nickname'];

                  return Card(
                    color: Colors.grey[900], // 리스트 아이템 배경 색상 설정
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(plan['profilePic'] ?? ''),
                                radius: 24,
                              ),
                              SizedBox(width: 10),
                              Text(
                                '${plan['nickname']}님의 운동 계획',
                                style: TextStyle(color: Colors.white), // 텍스트 색상 설정
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '날짜: ${plan['selected_date']}',
                            style: TextStyle(color: Colors.white), // 텍스트 색상 설정
                          ),
                          Text(
                            '운동: ${plan['selected_exercise']}',
                            style: TextStyle(color: Colors.white), // 텍스트 색상 설정
                          ),
                          Text(
                            '참가자: ${plan['selected_participants']}명',
                            style: TextStyle(color: Colors.white), // 텍스트 색상 설정
                          ),
                          Text(
                            '시작 시간: ${plan['selected_startTime']}',
                            style: TextStyle(color: Colors.white), // 텍스트 색상 설정
                          ),
                          Text(
                            '종료 시간: ${plan['selected_endTime']}',
                            style: TextStyle(color: Colors.white), // 텍스트 색상 설정
                          ),
                          Text(
                            '장소: ${plan['selected_location']}',
                            style: TextStyle(color: Colors.white), // 텍스트 색상 설정
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    print('참여하기 버튼 클릭됨');
                                  },
                                  child: Text('참여 신청'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white, // 버튼 배경 색상 설정
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (isCurrentUserPlan)
                                  ElevatedButton(
                                    onPressed: () {
                                      _confirmDelete(plan['id']); // plan['id'] 전달
                                    },
                                    child: Text('삭제하기'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red, // 버튼 배경 색상 설정
                                    ),
                                  ),
                              ],
                            ),
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
