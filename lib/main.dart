import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'search_screen.dart';
import 'add_screen.dart';
import 'profile_screen.dart';
import 'footer.dart';
import 'login_activity/login.dart'; // 로그인 화면 import
import 'login_activity/signup1.dart'; // 회원가입1 페이지 import
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
        '/login': (context) => LoginScreen(),
        '/signup1': (context) => Signup1Screen(),
        '/signup2': (context) => Signup2Screen(),
        '/profile': (context) => ProfileScreen(),
        '/add_plan': (context) => AddScreen(),
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

  Future<void> _onTabTapped(int index) async {
    if (index == 3) { // Profile tab
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        // 로그인이 되어 있으면 ProfileScreen으로 이동 (현재 페이지를 업데이트)
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(index);
      } else {
        // 로그인이 되어 있지 않으면 LoginScreen으로 이동
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
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
