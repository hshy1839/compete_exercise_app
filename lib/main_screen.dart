import 'package:flutter/material.dart';
import 'header.dart'; // Header 위젯을 import합니다.

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(), // Header 위젯을 추가합니다.
        Expanded(
          child: Center(
            child: Text('Main Screen Content'),
          ),
        ),
      ],
    );
  }
}
