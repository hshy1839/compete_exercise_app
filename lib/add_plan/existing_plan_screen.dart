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
        backgroundColor:  Color(0xFF25c387),
      ),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 및 D-day 표시를 하얀색 배경으로 묶기
              Container(
                padding: const EdgeInsets.all(16.0), // 내부 여백 설정
                decoration: BoxDecoration(
                  color:  Color(0xFF25c387),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5), // 그림자의 색과 투명도 설정
                      spreadRadius: 5, // 그림자가 퍼지는 정도
                      blurRadius: 5, // 그림자의 흐림 정도
                      offset: Offset(0, 3), // 그림자의 위치 (x, y)
                    ),
                  ],
                ),
                height: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20,),
                    // 날짜 및 D-day 표시
                    Row(
                      children: [
                        Text(
                          '${DateFormat('yyyy.MM.dd').format(selectedDate)}',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), // 날짜 스타일 설정
                        ),
                        // D-day 텍스트 표시
                        SizedBox(height: 10, width: 10,),
                        Text(
                          '${dDay > 0 ? 'D-${dDay}' : (dDay == 0 ? '오늘이에요' : '지난 계획입니다.')}',
                          style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),

                    // 닉네임 표시
                    Text(
                      '${planDetails!['nickname']} 님의 계획',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20), // 컨테이너 아래 여백
              // 계획 상세 정보 컨테이너
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(1.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('종류', planDetails!['selected_exercise'], 0), // 첫 번째 항목, 파란색
                    _buildInfoRow('시간', '${planDetails!['selected_startTime']} ~ ${planDetails!['selected_endTime']}', 1), // 두 번째 항목, 노란색
                    _buildInfoRow('장소', planDetails!['selected_location'], 2), // 세 번째 항목, 빨간색
                  ],
                ),
              ),


              SizedBox(height: 20), // 컨테이너 아래 여백
              _buildParticipantsList(),
            ],
          ),
        ),
      ),
    );

  }


  Widget _buildParticipantsList() {
    if (planDetails!['participants'] == null || planDetails!['participants'].isEmpty) {
      return _buildInfoRow('참여 인원', '없음', 0);
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
              Row(
                children: [
                  Icon(Icons.person, color: Colors.grey), // 아이콘 추가
                  SizedBox(width: 8), // 아이콘과 텍스트 간의 간격
                  Text(nickname, style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참여 인원', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ...participantWidgets, // 참여자 위젯 추가
        ],
      ),
    );
  }




  Widget _buildInfoRow(String title, String value, int index) {
    // index에 따라 순서대로 색상 설정
    final colors = [Colors.blue, Colors.yellow, Colors.red];
    final borderColor = colors[index % colors.length]; // 인덱스에 따라 색상 순환

    return Container(
      width: double.infinity, // 화면에 맞춰 넓이 설정
      decoration: BoxDecoration(
        color: Colors.white, // 배경색을 흰색으로 설정
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // 그림자의 색과 투명도 설정
            spreadRadius: 5, // 그림자가 퍼지는 정도
            blurRadius: 7, // 그림자의 흐림 정도
            offset: Offset(0, 3), // 그림자의 위치 (x, y)
          ),
        ],
        borderRadius: BorderRadius.circular(5), // 모서리를 둥글게 설정
        border: Border(
          left: BorderSide(color: borderColor, width: 5), // 왼쪽 테두리 색상과 너비 설정
        ),
      ),
      padding: const EdgeInsets.all(16.0), // 내부 여백 설정
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20), // 위아래 마진 설정
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.0), // title과 value 사이의 간격
          Text(
            value,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }




}
