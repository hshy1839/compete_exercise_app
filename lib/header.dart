import 'package:flutter/material.dart';
import './direct_message/direct_message1.dart';
import 'notification_screen.dart'; // 경로에 맞게 수정하세요.

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(vertical: 5.0), // 헤더 높이를 작게 설정
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 제목을 왼쪽에 배치
          SizedBox(width: 20),
          Expanded(
            child: Image.asset(
              'assets/images/app_logo.png',
              height: 20,
              fit: BoxFit.contain,
              alignment: Alignment.bottomLeft, // 이미지 비율을 유지하면서 크기 조정
            ),
          ),
          // 오른쪽에 DM 아이콘과 로그인 아이콘 추가
          Padding(
            padding: EdgeInsets.only(right: 20.0), // 오른쪽 마진 추가
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationScreen()),
                    );
                  },
                ),
                SizedBox(width: 10), // 아이콘 간격
                IconButton(
                  icon: Icon(Icons.message_outlined, color: Colors.black),
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
          ),
        ],
      ),
    );
  }
}
