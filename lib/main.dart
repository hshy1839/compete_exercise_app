import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest/add_plan/add_planning.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'search_screen.dart';
import 'add_plan/add_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/edit_profile.dart';
import 'footer.dart';
import 'login_activity/login.dart'; // 로그인 화면 import
import 'login_activity/signup.dart'; // 회원가입1 페이지 import
import 'add_plan/add_exercise_list.dart';
import 'direct_message/direct_message1.dart';
import 'direct_message/direct_message2.dart';
import './socket_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SocketService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compete Exercise App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<Widget>(
        future: _determineInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // 로딩 중 표시
          } else {
            return snapshot.data!; // 로그인 화면 또는 메인 화면 반환
          }
        },
      ),
      routes: {
        '/main': (context) => MainScreenWithFooter(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/profile': (context) => ProfileScreen(),
        '/add_screen': (context) => AddScreen(),
        '/add_exercise_list': (context) => AddExerciseList(),
        '/add_planning': (context) => AddPlanning(),
        '/edit_profile': (context) => EditProfile(),
        '/direct_message': (context) => DirectMessage1(),
      },
    );
  }

  Future<Widget> _determineInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      return MainScreenWithFooter(); // 로그인 상태면 메인 화면 반환
    } else {
      return LoginScreen(); // 로그인 상태가 아니면 로그인 화면 반환
    }
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
    EditProfile(),
    DirectMessage1(),
    MainScreenWithFooter(),
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
      bottomNavigationBar: Footer(onTabTapped: _onTabTapped, selectedIndex: _currentIndex),
    );
  }
}
