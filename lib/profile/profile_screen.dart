import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../header.dart';
import '../socket_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nickname = 'Loading...';
  int _postCount = 0; // 게시물 수
  int _followersCount = 0; // 팔로워 수
  int _followingCount = 0; // 팔로잉 수
  List<Map<String, dynamic>> exercisePlans = [];
  String? currentUserId;
  bool showCreatedPlans = true; // true면 내가 만든 기록, false면 내가 참여한 기록

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchExercisePlans();
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
              'nickname': plan['nickname'] ?? '알 수 없는 사용자',
              'selected_date': plan['selected_date'] ?? '알 수 없는 날짜',
              'selected_exercise': plan['selected_exercise'] ?? '알 수 없는 운동',
              'selected_participants': plan['selected_participants'] ?? '0',
              'participants': plan['participants'] ?? [],
              'selected_startTime': plan['selected_startTime'] ??
                  '알 수 없는 시작 시간',
              'selected_endTime': plan['selected_endTime'] ?? '알 수 없는 종료 시간',
              'selected_location': plan['selected_location'] ?? '알 수 없는 위치',
              'userId': plan['userId'] ?? '', // 만든 사람의 ID 추가
            };
          }).toList();
        });
      } else {
        print('운동 계획을 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('운동 계획을 가져오는 중 오류 발생: $e');
    }
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
      final responseData = jsonDecode(response.body);
      setState(() {
        _nickname = responseData['nickname'] ?? 'Unknown User';
        _postCount = responseData['postCount'] ?? 0;
        _followersCount = responseData['followersCount'] ?? 0;
        _followingCount = responseData['followingCount'] ?? 0;
        currentUserId = responseData['_id'];
      });
    } else {
      setState(() {
        _nickname = 'Error fetching user info';
      });
    }
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, '/edit_profile'); // 프로필 수정 페이지로 이동
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // 로그아웃 처리
    await prefs.remove('token'); // JWT 삭제

    // 소켓 연결 해제
    SocketService().disconnect();
    print('소켓 연결 해제됨'); // 소켓 해제 로그 출력

    Navigator.pushReplacementNamed(context, '/login'); // 로그인 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Header(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 70,
                color: Colors.grey[600],
              ),
              SizedBox(width: 20), // 아이콘 우측 마진
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _nickname,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    _postCount.toString(),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text('Posts', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    _followersCount.toString(),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text('Followers', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(width: 40),
              Column(
                children: [
                  Text(
                    _followingCount.toString(),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text('Following', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: ElevatedButton(
                  onPressed: _navigateToEditProfile,
                  child: Text('Edit Profile',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              SizedBox(width: 20),
              Container(
                width: 120,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  child:
                  Text('Logout', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: showCreatedPlans ? Colors.blue : Colors.grey,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    showCreatedPlans = true;
                  });
                },
                tooltip: '내가 만든 기록',
              ),
              SizedBox(width: 20),
              IconButton(
                icon: Icon(
                  Icons.group,
                  color: !showCreatedPlans ? Colors.blue : Colors.grey,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    showCreatedPlans = false;
                  });
                },
                tooltip: '내가 참여한 기록',
              ),
            ],
          ),
          SizedBox(height: 20),
          // 운동 계획 목록
          Expanded(
            child: ListView.builder(
              itemCount: exercisePlans.length,
              itemBuilder: (context, index) {
                final plan = exercisePlans[index];

                if (showCreatedPlans) {
                  // 내가 만든 기록
                  if (plan['userId'] == currentUserId) {
                    return _buildPlanCard(plan);
                  }
                } else {
                  // 내가 참여한 기록
                  if (plan['participants'] != null &&
                      (plan['participants'] as List).contains(currentUserId)) {
                    return _buildPlanCard(plan);
                  }
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan['nickname']}님의 계획',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '운동: ${plan['selected_exercise']}',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 5),
            Text(
              '날짜: ${plan['selected_date']}',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text(
              '시간: ${plan['selected_startTime']} ~ ${plan['selected_endTime']}',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text(
              '위치: ${plan['selected_location']}',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            Text(
              '참여 인원: ${plan['participants'].length} / ${plan['selected_participants']}',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            SizedBox(height: 10),
            // 내가 참여한 계획일 때만 '참여 해제' 버튼 표시
            if (plan['participants'] != null && (plan['participants'] as List).contains(currentUserId))
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    _showLeaveConfirmationDialog(context, plan['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // 버튼 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text('참여 해제', style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }


// 참여 해제 확인 대화상자 UI
  void _showLeaveConfirmationDialog(BuildContext context, String planId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('참여 해제'),
          content: Text('정말로 이 계획에서 참여 해제 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _leavePlan(planId);
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _leavePlan(String planId) {
    // Socket.IO를 통해 참여 해제 요청
    SocketService().socket.emit('leave_plan', {
      'userId': currentUserId,
      'planId': planId,
    });

    // 참여 해제가 성공했을 때 SnackBar 표시
    _showSnackBar('참여가 해제되었습니다!');
    setState(() {
      exercisePlans.removeWhere((plan) => plan['id'] == planId);
    });
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}