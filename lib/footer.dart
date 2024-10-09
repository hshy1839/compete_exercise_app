import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final Function(int) onTabTapped;
  final int selectedIndex; // 현재 선택된 탭의 인덱스 추가

  Footer({required this.onTabTapped, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white, // Footer 배경 색상 설정
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home_outlined,
              color: selectedIndex == 0 ? Colors.black : Color(0xFF25c387), // 선택된 경우 검은색
            ),
            onPressed: () {
              onTabTapped(0);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: selectedIndex == 1 ? Colors.black : Color(0xFF25c387), // 선택된 경우 검은색
            ),
            onPressed: () {
              onTabTapped(1);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add_box_outlined,
              color: selectedIndex == 2 ? Colors.black : Color(0xFF25c387), // 선택된 경우 검은색
            ),
            onPressed: () {
              onTabTapped(2);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: selectedIndex == 3 ? Colors.black : Color(0xFF25c387), // 선택된 경우 검은색
            ),
            onPressed: () {
              onTabTapped(3);
            },
          ),
        ],
      ),
    );
  }
}
