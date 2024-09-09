import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final Function(int) onTabTapped;

  Footer({required this.onTabTapped});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              onTabTapped(0);
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              onTabTapped(1);
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              onTabTapped(2);
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              onTabTapped(3);
            },
          ),
        ],
      ),
    );
  }
}
