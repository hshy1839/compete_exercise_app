import 'package:flutter/material.dart';
import '../header.dart'; // Ensure to import the Header widget

class AddExerciseList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 날짜를 가져오기
    final DateTime selectedDate = ModalRoute.of(context)!.settings.arguments as DateTime;

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
              'Select Exercise',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildExerciseButton(context, 'Running', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, 'Weight Training', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, 'Yoga', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, 'Cycling', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, 'Swimming', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, '필라테스', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, '축구', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, '농구', '/add_planning', selectedDate),
            SizedBox(height: 10),
            _buildExerciseButton(context, '야구', '/add_planning', selectedDate),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildExerciseButton(BuildContext context, String exerciseName, String route, DateTime selectedDate) {
    return ElevatedButton(
      onPressed: () {
        // Handle exercise button click
        Navigator.pushNamed(
          context,
          route,
          arguments: {'date': selectedDate, 'exercise': exerciseName}, // Pass both date and exercise
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50), // Make button width full width
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Square corners
        ),
      ),
      child: Text(
        exerciseName,
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
