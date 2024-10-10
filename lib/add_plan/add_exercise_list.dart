import 'package:flutter/material.dart';
import '../header.dart'; // Ensure to import the Header widget

class AddExerciseList extends StatefulWidget {
  @override
  _AddExerciseListState createState() => _AddExerciseListState();
}

class _AddExerciseListState extends State<AddExerciseList> {
  final TextEditingController _controller = TextEditingController(); // TextEditingController for custom input
  String? customExercise; // To store user's custom input

  @override
  Widget build(BuildContext context) {
    // 날짜를 안전하게 가져오기 (null 처리)
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final DateTime selectedDate = args is DateTime ? args : DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Set height for the header
        child: Header(), // Use the Header widget
      ),
      body: SingleChildScrollView( // Scrollable
    child: Padding(
    padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, // 화면의 가로 크기를 꽉 채움
              height: 250.0,         // 세로 크기를 200으로 설정
              decoration: BoxDecoration(
                color: Color(0xFF25c387),    // 배경색
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)), // 하단 모서리에만 둥근 테두리 추가
              ),
              child: Align(
                alignment: Alignment.centerLeft, // 왼쪽 하단에 정렬
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Padding for better spacing
                  child: Text(
                    '약속 종류를 선택하세요',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ), // 왼쪽 하단에 정렬된 텍스트
                ),
              ),
            ),
            SizedBox(height: 40),
            // Single square buttons for all activities
            _buildSquareButton(context, '운동 약속', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildSquareButton(context, '술 약속', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildSquareButton(context, '밥 약속', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildSquareButton(context, '영화 약속', '/add_planning', selectedDate),
            SizedBox(height: 20),
            // "기타" 입력 필드 및 버튼 추가
            _buildCustomExerciseInput(context, selectedDate),
          ],
        ),
      ),
      ),
    );
  }

  // "기타" 입력 필드 및 버튼
  Widget _buildCustomExerciseInput(BuildContext context, DateTime selectedDate) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백 설정
      padding: EdgeInsets.all(16.0), // Padding for better spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        children: [
          // 입력 필드
          Expanded(
            child: TextFormField(
              controller: _controller, // Controller to capture user input
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '기타 활동을 입력하세요',
              ),
              maxLines: 1, // 줄 수를 1로 설정하여 입력 필드 줄이기
            ),
          ),
          SizedBox(width: 10), // 아이콘과 입력 필드 사이의 간격
          // > 아이콘 버튼
          GestureDetector(
            onTap: () {
              // 입력값을 저장하고 이동
              if (_controller.text.isNotEmpty) {
                customExercise = _controller.text;
                Navigator.pushNamed(
                  context,
                  '/add_planning',
                  arguments: {'date': selectedDate, 'exercise': customExercise}, // Pass date and custom exercise
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(0.0), // 아이콘 주변 패딩
              child: Icon(Icons.chevron_right, color: Colors.grey), // > 아이콘
            ),
          ),
        ],
      ),
    );
  }


  // 정사각형 버튼을 생성하는 함수
  Container _buildSquareButton(BuildContext context, String exerciseName, String route, DateTime selectedDate) {
    IconData iconData;

    // 아이콘을 약속에 맞게 설정
    switch (exerciseName) {
      case '운동 약속':
        iconData = Icons.directions_run; // 축구 아이콘
        break;
      case '술 약속':
        iconData = Icons.local_bar; // 술 아이콘
        break;
      case '밥 약속':
        iconData = Icons.restaurant; // 식사 아이콘
        break;
      case '영화 약속':
        iconData = Icons.movie; // 영화 아이콘
        break;
      default:
        iconData = Icons.error; // 기본 아이콘
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백 설정
      child: ElevatedButton(
        onPressed: () {
          // Handle exercise button click and navigate
          Navigator.pushNamed(
            context,
            route,
            arguments: {'date': selectedDate, 'exercise': exerciseName}, // Pass both date and exercise
          );
        },
        style: ElevatedButton.styleFrom(
          minimumSize: Size(100, 100), // Set fixed size for square buttons
          padding: EdgeInsets.all(20.0), // Padding for larger click area
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Rounded corners for aesthetics
          ),
          backgroundColor: Colors.white, // Set button color
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 공간을 균등하게 나누기
          children: [
            Row(
              children: [
                Icon(iconData, color: Color(0xFF25c387)), // 아이콘 추가
                SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격
                Text(
                  exerciseName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: Colors.grey), // 우측 화살표 아이콘 추가
          ],
        ),
      ),
    );
  }
}
