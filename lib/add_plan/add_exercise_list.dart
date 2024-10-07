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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Set height for the header
        child: Header(), // Use the Header widget
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Exercise',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildExpansionTile(context, '운동 약속', selectedDate, [
              '축구 약속',
              '풋살 약속',
              '농구 약속',
              '러닝 약속',
              '야구',
              '웨이트 약속',
              '기타',
            ]),
            SizedBox(height: 20),
            _buildExpansionTile(context, '게임 약속', selectedDate, [
              '롤',
              '피파',
              '배그',
              '서든어택',
              '발로란트',
              '기타',
            ]),
            SizedBox(height: 10),
            _buildExerciseButton(context, '술 약속', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, '밥 약속', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, '영화 약속', '/add_planning', selectedDate),
            SizedBox(height: 20),
            // "기타" 입력 필드 및 버튼 추가
            _buildCustomExerciseInput(context, selectedDate),
          ],
        ),
      ),
    );
  }

  // ExpansionTile을 이용하여 운동 및 게임 목록 확장 기능 추가
  Widget _buildExpansionTile(BuildContext context, String title, DateTime selectedDate, List<String> exercises) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: exercises.map((exercise) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: _buildExerciseButton(context, exercise, '/add_planning', selectedDate),
        );
      }).toList(),
    );
  }

  // "기타" 입력 필드 및 버튼
  Widget _buildCustomExerciseInput(BuildContext context, DateTime selectedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기타 활동 직접 입력',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: _controller, // Controller to capture user input
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: '기타 활동을 입력하세요',
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
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
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50), // Make button full width
            padding: EdgeInsets.symmetric(vertical: 15.0), // Padding for larger click area
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Square corners
            ),
          ),
          child: Text(
            '기타 입력 확인',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  ElevatedButton _buildExerciseButton(BuildContext context, String exerciseName, String route, DateTime selectedDate) {
    return ElevatedButton(
      onPressed: () {
        // Handle exercise button click and navigate
        Navigator.pushNamed(
          context,
          route,
          arguments: {'date': selectedDate, 'exercise': exerciseName}, // Pass both date and exercise
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50), // Make button full width
        padding: EdgeInsets.symmetric(vertical: 15.0), // Padding for larger click area
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Square corners
        ),
      ),
      child: Text(
        exerciseName,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
