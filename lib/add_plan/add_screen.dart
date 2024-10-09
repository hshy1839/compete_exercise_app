import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // table_calendar 패키지 import
import '../header.dart'; // Header 위젯이 정의된 파일을 import

class AddScreen extends StatefulWidget {
  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Header(),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2098),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDay = focusedDay; // Update the focused day
              });
            },
            calendarStyle: CalendarStyle(
              // 선택한 날짜와 현재 날짜의 색상 설정
              selectedDecoration: BoxDecoration(
                color: Color(0xFF25c387), // 선택한 날짜 색상
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF25c387)), // 오늘 날짜 외곽선 색상
              ),
              todayTextStyle: TextStyle(
                color: Colors.black, // 기본 날짜 숫자 색상
              ),
              defaultDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              weekendDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              defaultTextStyle: TextStyle(
                color: Colors.black, // 기본 날짜 숫자 색상
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // 2주 버튼 숨기기
              titleCentered: true, // 제목 중앙 정렬
              leftChevronVisible: true, // 왼쪽 화살표 버튼 표시
              rightChevronVisible: true, // 오른쪽 화살표 버튼 표시
            ),
          ),
          SizedBox(height: 50,),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, '/add_exercise_list',
                        arguments: _selectedDate);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 모서리 반경 0
                    ),
                  ),
                  child: Text(
                    '계획 추가',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
