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

  @override
  void initState() {
    super.initState();
    _fetchExercisePlans();
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
              'username': plan['username'] ?? 'Unknown User',
              'selected_date': plan['selected_date'] ?? 'Unknown Date',
              'selected_exercise': plan['selected_exercise'] ?? 'Unknown Exercise',
              'selected_participants': plan['selected_participants'] ?? 'Unknown Participants',
              'selected_startTime': plan['selected_startTime'] ?? 'Unknown Start Time',
              'selected_endTime': plan['selected_endTime'] ?? 'Unknown End Time',
              'selected_location': plan['selected_location'] ?? 'Unknown Location',
              // 'profilePic': 'https://example.com/profile.jpg', // 프로필 사진 URL을 필요에 따라 조정
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

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // 로그아웃 처리

    Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh, // 새로 고침 기능
        child: Column(
          children: [
            // 사용자 정의 Header 위젯을 상단에 배치
            Header(),
            Expanded(
              child: ListView.builder(
                itemCount: exercisePlans.length,
                itemBuilder: (context, index) {
                  final plan = exercisePlans[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      leading: CircleAvatar(
                        // 프로필 사진 URL이 필요하면 여기에 설정
                        backgroundImage: NetworkImage(plan['profilePic'] ?? ''),
                        radius: 24,
                      ),
                      title: Text('${plan['username']}님의 운동 계획'), // 사용자 이름 표시
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('날짜: ${plan['selected_date']}'),
                          Text('운동: ${plan['selected_exercise']}'),
                          Text('참가자: ${plan['selected_participants']}명'),
                          Text('시작 시간: ${plan['selected_startTime']}'),
                          Text('종료 시간: ${plan['selected_endTime']}'),
                          Text('장소: ${plan['selected_location']}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Icon(Icons.more_vert),
                      // 오른쪽 끝에 더보기 아이콘 추가
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _logout(context),
                child: Text('로그아웃'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
