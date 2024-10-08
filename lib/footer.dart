import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final Function(int) onTabTapped;

  Footer({required this.onTabTapped});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white, // Footer 배경 색상 설정
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: Colors.black, // 아이콘 색상 설정
            ),
            onPressed: () {
              onTabTapped(0);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.black, // 아이콘 색상 설정
            ),
            onPressed: () {
              onTabTapped(1);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.black, // 아이콘 색상 설정
            ),
            onPressed: () {
              onTabTapped(2);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: Colors.black, // 아이콘 색상 설정
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
