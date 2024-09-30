import 'package:flutter/material.dart';
import './direct_message/direct_message1.dart'; // 경로에 맞게 수정하세요.

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 제목을 왼쪽에 배치
          Text(
            'SSS',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          // 오른쪽에 DM 아이콘과 로그인 아이콘 추가
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_on_rounded, color: Colors.white),
                onPressed: () {
                  // 알림 아이콘 클릭 시 동작
                },
              ),
              SizedBox(width: 10), // 아이콘 간격
              IconButton(
                icon: Icon(Icons.message, color: Colors.white),
                onPressed: () {
                  // message 아이콘 클릭 시 DirectMessage1으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DirectMessage1()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
