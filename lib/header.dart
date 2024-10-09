import 'package:flutter/material.dart';
import './direct_message/direct_message1.dart';
import 'notification_screen.dart';
import 'search_screen.dart';

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // 부모 컨테이너의 높이를 늘림
      padding: EdgeInsets.symmetric(vertical: 5.0), // 헤더 높이를 설정
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 제목을 왼쪽에 배치
          SizedBox(width: 20),
          Expanded(
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain, // 비율을 유지하면서 크기를 조정
              alignment: Alignment.centerLeft, // 이미지를 왼쪽에 정렬
              height: 30,
            ),
          ),
          // 오른쪽에 아이콘 추가
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
                  icon: Icon(Icons.search, color: Colors.black), // 검색 아이콘 추가
                  onPressed: () {
                    // 검색 아이콘 클릭 시 SearchScreen으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchScreen()),
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
