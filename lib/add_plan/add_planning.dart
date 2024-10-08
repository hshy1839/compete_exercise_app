import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../header.dart'; // Ensure to import the Header widget

class AddPlanning extends StatefulWidget {
  @override
  _AddPlanningState createState() => _AddPlanningState();
}

class _AddPlanningState extends State<AddPlanning> {
  final _participantsCountController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> participants = []; // List to store participants
  bool _isPrivateSearch = false;

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  DateTime? _selectedDate;
  String? _exerciseType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _selectedDate = arguments['date'];
      _exerciseType = arguments['exercise'];
    }
  }

  Future<void> _searchNickname() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('http://localhost:8864/api/users/search?nickname=$query'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      setState(() {
        _searchResults = responseData.map((item) {
          return {
            'nickname': item['nickname'] ?? '닉네임 없음',
            'id': item['_id'] ?? '아이디 없음',
            'isFollowing': item['isFollowing'] ?? false
          };
        }).toList();
      });
    } else {
      print('검색 실패: ${response.statusCode}');
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
          _startTimeController.text = _formatTimeOfDay(selectedTime);
        } else {
          _endTime = selectedTime;
          _endTimeController.text = _formatTimeOfDay(selectedTime);
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitPlanning() async {
    if (_participantsCountController.text.isEmpty || participants.isEmpty || _startTimeController.text.isEmpty || _endTimeController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요.')),
      );
      return;
    }

    final url = 'http://localhost:8864/api/users/planning';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'selected_date': _selectedDate?.toIso8601String(),
      'selected_exercise': _exerciseType,
      'selected_participants': _participantsCountController.text, // 참가자 수를 입력된 값으로 전달
      'selected_startTime': _startTimeController.text,
      'selected_endTime': _endTimeController.text,
      'selected_location': _locationController.text,
      'participants': participants.map((p) => p['id']).toList(),
      'isPrivate': _isPrivateSearch
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('성공'),
            content: Text('계획이 저장되었습니다!'),
            actions: [
              TextButton(
                child: Text('확인'),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit planning: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _addParticipant(Map<String, dynamic> user) {
    setState(() {
      participants.add(user);
      _searchResults.removeWhere((item) => item['id'] == user['id']);
    });
  }

  void _removeParticipant(String userId) {
    setState(() {
      participants.removeWhere((user) => user['id'] == userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Header(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Your Exercise',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Selected Date: ${_selectedDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              'Exercise Type: ${_exerciseType ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text(
              '참가자 수',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _participantsCountController,
              keyboardType: TextInputType.number, // 숫자 키보드 타입 사용
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: '참가자 수를 입력하세요',
              ),
            ),
            SizedBox(height: 20),
            Text(
              '시작시간',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _startTimeController,
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select start time',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () => _selectTime(context, true),
            ),
            SizedBox(height: 20),
            Text(
              '종료시간',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _endTimeController,
              readOnly: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select end time',
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: () => _selectTime(context, false),
            ),
            SizedBox(height: 20),
            Text(
              '장소',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter location',
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '공개 여부: ${_isPrivateSearch ? "Private" : "Public"}',
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: _isPrivateSearch,
                  onChanged: (value) {
                    setState(() {
                      _isPrivateSearch = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              '참가자 추가',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _searchController,
              onChanged: (_) => _searchNickname(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search by nickname',
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(user['nickname']),
                    subtitle: Text(user['isFollowing'] ? 'Following' : 'Not Following'),
                    trailing: ElevatedButton(
                      child: Text('Add'),
                      onPressed: () => _addParticipant(user),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Added Participants',
              style: TextStyle(fontSize: 18),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participant = participants[index];
                  return ListTile(
                    title: Text(participant['nickname']),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () => _removeParticipant(participant['id']),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                child: Text('Submit Planning'),
                onPressed: _submitPlanning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
