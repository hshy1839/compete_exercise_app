import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExistingPlanScreen extends StatefulWidget {
  final String planId;
  final String nickname;

  ExistingPlanScreen({required this.planId, required this.nickname}); // 생성자에서 planId를 전달받음

  @override
  _ExistingPlanScreenState createState() => _ExistingPlanScreenState();
}

class _ExistingPlanScreenState extends State<ExistingPlanScreen> {
  Map<String, dynamic>? planDetails;

  @override
  void initState() {
    super.initState();
    _fetchPlanDetails();
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
      } else {
        print('운동 계획을 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('운동 계획 세부 정보를 가져오는 중 오류 발생: $e');
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
        title: Text('운동 계획 세부 정보'),
        elevation: 0, // 그림자 제거
        backgroundColor: Colors.teal, // 앱 바 색상 변경
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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow('운동:', planDetails!['selected_exercise']),
                  _buildInfoRow('날짜:', planDetails!['selected_date']),
                  _buildInfoRow('시작 시간:', planDetails!['selected_startTime']),
                  _buildInfoRow('종료 시간:', planDetails!['selected_endTime']),
                  _buildInfoRow('장소:', planDetails!['selected_location']),
                  _buildInfoRow(
                    '참여 인원:',
                    '${planDetails!['participants'].length} / ${planDetails!['selected_participants']}',
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
