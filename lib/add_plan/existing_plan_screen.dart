import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ExistingPlanScreen extends StatefulWidget {
  final String planId;
  final String nickname;

  ExistingPlanScreen({required this.planId, required this.nickname}); // 생성자에서 planId를 전달받음

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
    _fetchUserNicknames();
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
  Future<void> _fetchPlanDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8864/api/users/planinfo/${widget.planId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          planDetails = data; // 운동 계획 세부 정보를 설정
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
      Map<String, String> nicknameMap = {}; // ID와 닉네임을 매핑할 맵

      for (String userId in participantIds) {
        try {
          final response = await http.get(
            Uri.parse('http://localhost:8864/api/users/userinfo/$userId'),

          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            nicknameMap[userId] = data['nickname']; // ID를 키로 닉네임 저장
          } else {
            nicknameMap[userId] = '알 수 없음'; // 사용자 정보를 가져오지 못한 경우 '알 수 없음' 추가
          }
        } catch (e) {
          nicknameMap[userId] = '알 수 없음'; // 예외가 발생한 경우 '알 수 없음' 추가
        }
      }

      setState(() {
        participantsNicknames = nicknameMap; // nicknames 맵에 닉네임 저장
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
        body: Center(child: CircularProgressIndicator()), // 로딩 인디케이터
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${planDetails!['nickname']} 님의 계획',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),),
        elevation: 0, // 그림자 제거
        backgroundColor: Colors.white, // 앱 바 색상 변경
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4, // 카드 그림자 효과
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // 카드 모서리 둥글게
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${planDetails!['nickname']}님의 계획',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow('종류:', planDetails!['selected_exercise']),
                  _buildInfoRow('날짜:', planDetails!['selected_date']),
                  _buildInfoRow('시작 시간:', planDetails!['selected_startTime']),
                  _buildInfoRow('종료 시간:', planDetails!['selected_endTime']),
                  _buildInfoRow('장소:', planDetails!['selected_location']),
                  _buildInfoRow(
                    '참여 인원:',
                    planDetails!['participants'] != null && planDetails!['participants'].isNotEmpty
                        ? planDetails!['participants'].map((id) => participantsNicknames?[id] ?? '알 수 없음').join(', ')
                        : '없음',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
