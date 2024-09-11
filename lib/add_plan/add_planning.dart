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
  final _participantsController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _locationController = TextEditingController();

  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  DateTime? _selectedDate;
  String? _exerciseType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve arguments safely in didChangeDependencies
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _selectedDate = arguments['date'];
      _exerciseType = arguments['exercise'];
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
    final url = 'http://localhost:8864/api/users/planning'; // Replace with your server URL

    // Get JWT token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token', // Add token to Authorization header
    };

    final body = jsonEncode({
      'selected_date': _selectedDate?.toIso8601String(),
      'selected_exercise': _exerciseType,
      'selected_participants': _participantsController.text,
      'selected_startTime': _startTimeController.text,
      'selected_endTime': _endTimeController.text,
      'selected_location': _locationController.text,
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        // Handle successful response
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
        // Handle error response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit planning')),
        );
      }
    } catch (e) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Set height for the header
        child: Header(), // Use the Header widget
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
              controller: _participantsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: '몇명인지 입력하세요',
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
            ElevatedButton(
              onPressed: _submitPlanning,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Make button width full width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Square corners
                ),
              ),
              child: Text(
                'Submit',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _participantsController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
