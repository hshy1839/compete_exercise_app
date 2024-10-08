import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'socket_service.dart'; // SocketService 파일 경로에 맞게 수정

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> notifications = [];
  String? currentUserId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchUserInfo();
  }

  void _initializeSocket() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.connect();
    socketService.on('receiveNotifications', _receiveNotifications);
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8864/api/users/userinfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            currentUserId = data['_id'];
            isLoading = false;
          });
          _requestNotifications(currentUserId);
        }
      } else {
        print('사용자 정보를 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('사용자 정보를 가져오는 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _requestNotifications(String? userId) {
    if (!mounted) return;
    if (userId != null) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('requestNotifications', userId);
    }
  }

  void _receiveNotifications(dynamic data) {
    if (!mounted) return;
    if (data is List<dynamic>) {
      if( mounted) {
        setState(() {
          notifications.clear();
          notifications.addAll(data.map((item) => item as Map<String, dynamic>));
        });
        print('받은 알림: ${notifications.length}개');
      }
      else { return; }
    } else {
      print('알림 데이터 형식이 올바르지 않습니다.');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(child: Text('알림이 없습니다.'))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return GestureDetector(
            onTap: () => _onNotificationTap(notification),
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.notifications, color: Colors.black54),
                ),
                title: Text(
                  notification['message'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "보낸 사용자 ID: ${notification['userId']}",
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onNotificationTap(Map<String, dynamic> notification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: notification),
      ),
    );
  }
}

// 알림 세부 정보 화면
class NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  NotificationDetailScreen({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림 세부 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '메시지: ${notification['message']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              '보낸 사용자 ID: ${notification['userId']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              '알림 ID: ${notification['_id']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              '생성 시간: ${notification['createdAt']}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}