import 'package:flutter/material.dart';
import 'package:quest/add_plan/add_planning.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'search_screen.dart';
import 'add_plan/add_screen.dart';
import 'profile_screen.dart';
import 'footer.dart';
import 'login_activity/login.dart'; // 로그인 화면 import
import 'login_activity/signup.dart'; // 회원가입1 페이지 import
import 'add_plan/add_exercise_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  get url => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compete Exercise App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreenWithFooter(), // 로그인 여부에 관계없이 항상 MainScreenWithFooter 표시
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/profile': (context) => ProfileScreen(),
        '/add_screen': (context) => AddScreen(),
        '/add_exercise_list': (context) => AddExerciseList(),
        '/add_planning': (context) => AddPlanning(),
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
    AddExerciseList(),
    LoginScreen(),
    SignupScreen(),
  ];

  Future<void> _onTabTapped(int index) async {
    if (index == 3) { // Profile tab
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(index);
      } else {
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
