import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'search_screen.dart';
import 'add_screen.dart';
import 'profile_screen.dart';
import 'footer.dart';
import 'login_activity/login.dart'; // 로그인 화면 import
import 'login_activity//signup1.dart'; // 회원가입1 페이지 import
import 'login_activity/signup2.dart'; // 회원가입2 페이지 import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compete Exercise App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreenWithFooter(),
      routes: {
        '/main': (context) => MainScreen(),
        '/login': (context) => LoginScreen(),
        '/signup1': (context) => Signup1Screen(),
        '/signup2': (context) => Signup2Screen(),
      },
    );
  }
}

class MainScreenWithFooter extends StatefulWidget {
  @override
  _MainScreenWithFooterState createState() => _MainScreenWithFooterState();
}

class _MainScreenWithFooterState extends State<MainScreenWithFooter> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    MainScreen(),
    SearchScreen(),
    AddScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 3) {
      Navigator.pushNamed(context, '/login');
    } else {
      _pageController.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Footer(onTabTapped: _onTabTapped),
    );
  }
}
