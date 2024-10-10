import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quest/add_plan/add_planning.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'search_screen.dart';
import 'add_plan/add_screen.dart';
import 'profile/edit_profile.dart';
import 'profile/profile_screen.dart';
import 'footer.dart';
import 'login_activity/login.dart'; // 로그인 화면 import
import 'login_activity/signup.dart'; // 회원가입1 페이지 import
import 'add_plan/add_exercise_list.dart';
import 'direct_message/direct_message1.dart';
import 'direct_message/direct_message2.dart';
import 'package:flutter/services.dart';
import './socket_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
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
      body: RefreshIndicator( // RefreshIndicator 추가
        onRefresh: _refresh, // 새로 고침 콜백 설정
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _pages,
        ),
      ),
      bottomNavigationBar: Footer(onTabTapped: _onTabTapped, selectedIndex: _currentIndex),
    );
  }

// 새로 고침 함수 구현
  Future<void> _refresh() async {
    // 여기에 데이터를 새로 고침하는 로직을 추가하세요.
    // 예를 들어, 서버에서 데이터를 가져오거나 상태를 초기화하는 등의 작업을 수행할 수 있습니다.
    setState(() {
      // 필요한 상태를 업데이트합니다.
    });
  }

}
