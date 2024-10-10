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
  final _titleController = TextEditingController();
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
      Uri.parse('http://43.202.64.70:8864/api/users/search?nickname=$query'),
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
    if (_participantsCountController.text.isEmpty || (_isPrivateSearch && participants.isEmpty) || _startTimeController.text.isEmpty || _endTimeController.text.isEmpty || _locationController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요.')),
      );
      return;
    }

    final url = 'http://43.202.64.70:8864/api/users/planning';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'selected_date': _selectedDate?.toIso8601String(),
      'selected_exercise': _exerciseType,
      'planTitle': _titleController.text,
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
                  Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
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
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Header(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0.0), // 전체 화면에 대한 패딩 추가
        children: [
          // 특정 Container (패딩 없음)
          Container(
            width: double.infinity,
            height: 250.0,
            decoration: BoxDecoration(
              color: Color(0xFF25c387),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.0)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(20.0), // 패딩을 0으로 조정
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 60),
                    Text(
                      '세부 항목을 입력하세요',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '선택된 날짜 ',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade100),
                    ),
                    Text(
                      '${_selectedDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                    Text(
                      '선택된 약속 종류',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade100),
                    ),
                    Text(
                      ' ${_exerciseType ?? 'N/A'}',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 20), // Container와 다음 요소 간의 간격
          _buildTextField('계획제목', _titleController, '제목을 입력하세요'),
          SizedBox(height: 20),
          _buildTextField('참가자 수', _participantsCountController, '참가자 수를 입력하세요', keyboardType: TextInputType.number),
          SizedBox(height: 20),
          _buildReadOnlyTextField('시작시간', _startTimeController, 'Select start time', () => _selectTime(context, true)),
          SizedBox(height: 20),
          _buildReadOnlyTextField('종료시간', _endTimeController, 'Select end time', () => _selectTime(context, false)),
          SizedBox(height: 20),
          _buildTextField('장소', _locationController, 'Enter location'),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0), // 양옆에 16의 마진 추가
            decoration: BoxDecoration(
              color: Colors.white, // 배경색을 흰색으로 설정
              borderRadius: BorderRadius.circular(8), // 모서리를 둥글게 설정 (선택사항)
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.7), // 그림자 색상
                  spreadRadius: 2, // 그림자 퍼짐 정도
                  blurRadius: 5, // 그림자 흐림 정도
                  offset: Offset(0, 3), // 그림자의 위치
                ),
              ],
            ),
            padding: EdgeInsets.all(20), // 안쪽 여백
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 정렬을 왼쪽으로 설정
                  children: [
                    Text(
                      '공개 여부',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_isPrivateSearch ? "Private" : "Public"}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 20,),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300), // 애니메이션 지속 시간
                          child: Icon(
                            _isPrivateSearch ? Icons.lock : Icons.lock_open, // 조건에 따라 아이콘 선택
                            color: _isPrivateSearch ? Colors.green : Colors.blue, // 상태에 따른 색상
                            key: ValueKey<bool>(_isPrivateSearch), // 키를 통해 상태를 식별
                          ),
                        ),
                        SizedBox(width: 20), // 아이콘과 텍스트 사이에 여백 추가
                        Switch(
                          value: _isPrivateSearch,
                          onChanged: (value) {
                            setState(() {
                              _isPrivateSearch = value; // 상태 변경
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: 10), // Toggle 버튼과의 간격 조정
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white, // 배경색을 흰색으로 설정
              borderRadius: BorderRadius.circular(8), // 모서리를 둥글게 설정 (선택사항)
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.7), // 그림자 색상
                  spreadRadius: 2, // 그림자 퍼짐 정도
                  blurRadius: 5, // 그림자 흐림 정도
                  offset: Offset(0, 3), // 그림자의 위치
                ),
              ],
            ),
            padding: EdgeInsets.all(20), // 안쪽 여백
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 정렬을 왼쪽으로 설정
              children: [
                if (_isPrivateSearch) ...[
                  Text(
                    '참가자 추가',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20,),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _searchNickname();
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '검색할 닉네임 입력',
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 80,
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          title: Text(user['nickname']),
                          trailing: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => _addParticipant(user),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '선택된 참가자:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 50,
                    child: ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        return ListTile(
                          title: Text(participant['nickname']),
                          trailing: IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => _removeParticipant(participant['id']),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 20),
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 16.0), // 양옆에 16의 마진 추가
            child: ElevatedButton(
              onPressed: _submitPlanning,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // 배경색을 파란색으로 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 모서리 반경을 0으로 설정
                ),
              ),
              child: Text('계획 만들기', style: TextStyle(color: Colors.white)),
            ),
          ),

          SizedBox(height: 30),
        ],
      ),
    );
  }




  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.0), // Text와 TextField 사이의 간격
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: hint,
              contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0), // TextField 내부 패딩
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyTextField(String label, TextEditingController controller, String hint, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 18)),
          SizedBox(height: 8.0), // Text와 TextField 사이의 간격
          TextField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: hint,
              suffixIcon: Icon(Icons.access_time),
              contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),// TextField 내부 패딩
            ),
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}