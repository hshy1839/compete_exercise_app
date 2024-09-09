import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 제목을 왼쪽에 배치
          Text(
            'SSS',
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
          // 오른쪽에 DM 아이콘과 로그인 아이콘 추가
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_on_rounded),
                onPressed: () {
                  // DM 아이콘 클릭 시 동작
                },
              ),
              SizedBox(width: 10), // 아이콘 간격
              IconButton(
                icon: Icon(Icons.message),
                onPressed: () {
                  // 로그인 아이콘 클릭 시 동작
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
