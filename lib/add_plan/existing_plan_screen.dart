import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExistingPlanScreen extends StatefulWidget {
  final String planId;
  final String nickname;

  ExistingPlanScreen({required this.planId, required this.nickname});

  @override
  _ExistingPlanScreenState createState() => _ExistingPlanScreenState();
}

class _ExistingPlanScreenState extends State<ExistingPlanScreen> {
  Map<String, dynamic>? planDetails;
  String? currentUserNickname;
  String? currentUserId;
  Map<String, dynamic>? participantsNicknames;

  @override
  void initState() {
    super.initState();
    _fetchPlanDetails();
    _fetchUserInfo();
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
          currentUserNickname = data['nickname'];
          currentUserId = data['_id'];
        });
      } else {
        print('사용자 정보를 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 정보를 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> _fetchPlanDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8864/api/users/planinfo/${widget.planId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          planDetails = data;
        });
        await _fetchUserNicknames();
      } else {
        print('운동 계획을 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('운동 계획 세부 정보를 가져오는 중 오류 발생: $e');
    }
  }

  Future<void> _fetchUserNicknames() async {
    if (planDetails?['participants'] != null && planDetails!['participants'].isNotEmpty) {
      List<String> participantIds = List<String>.from(planDetails!['participants']);
      Map<String, String> nicknameMap = {};

      for (String userId in participantIds) {
        try {
          final response = await http.get(
            Uri.parse('http://localhost:8864/api/users/userinfo/$userId'),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            nicknameMap[userId] = data['nickname'];
          } else {
            nicknameMap[userId] = '알 수 없음';
          }
        } catch (e) {
          nicknameMap[userId] = '알 수 없음';
        }
      }

      setState(() {
        participantsNicknames = nicknameMap;
      });
      print(participantsNicknames);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (planDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('운동 계획 세부 정보'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 현재 날짜 구하기
    DateTime selectedDate = DateTime.parse(planDetails!['selected_date']);
    DateTime currentDate = DateTime.now();

    // D-day 계산
    int dDay = selectedDate.difference(currentDate).inDays;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(''),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 및 D-day 표시
                Row(
                  children: [
                    Text(
                      '${DateFormat('yyyy.MM.dd').format(selectedDate)}',
                      style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold), // 날짜 스타일 설정
                    ),
                    // D-day 텍스트 표시
                    SizedBox(height: 10, width: 10,),
                    Text(
                      '${dDay > 0 ? 'D-${dDay}' : (dDay == 0 ? '오늘이에요' : '지난 계획입니다.')}',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20,),
                Text(
                  '${planDetails!['nickname']} 님의 계획',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 50),
                _buildInfoRow('종류:', planDetails!['selected_exercise']),
                _buildInfoRow('시간:', '${planDetails!['selected_startTime']} ~ ${planDetails!['selected_endTime']}'),
                _buildInfoRow('장소:', planDetails!['selected_location']),
                _buildParticipantsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildParticipantsList() {
    if (planDetails!['participants'] == null || planDetails!['participants'].isEmpty) {
      return _buildInfoRow('참여 인원:', '없음');
    }

    final isCurrentUserPlan = currentUserNickname == planDetails!['nickname'];

    List<Widget> participantWidgets = planDetails!['participants'].map<Widget>((id) {
      String nickname = participantsNicknames?[id] ?? '알 수 없음';

      return Card(
        color: Colors.white,
        elevation: 2, // 카드의 그림자 효과
        margin: EdgeInsets.symmetric(vertical: 1), // 카드 간의 여백
        child: Padding(
          padding: EdgeInsets.all(16), // 카드 내부 패딩
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nickname, style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              if (isCurrentUserPlan)
                TextButton(
                  onPressed: () => {}, // 삭제 요청 다이얼로그 호출
                  child: Text('퇴장', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참여 인원:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ...participantWidgets, // 참여자 위젯 추가
        ],
      ),
    );
  }



  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
