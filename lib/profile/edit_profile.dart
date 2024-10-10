import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // For DateFormat

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}
class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _birthdateString = ''; // Use String instead of DateTime
  String _phoneNumber = '';
  String _nickname = ''; // Add this line

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print('Fetching user info with token: $token'); // Debug print

    try {
      final response = await http.get(
        Uri.parse('http://43.202.64.70:8864/api/users/userinfo'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _name = responseData['name'] ?? 'Unknown Name';
          _birthdateString = responseData['birthdate'] ?? ''; // Store birthdate as String
          _phoneNumber = responseData['phoneNumber'] ?? 'Unknown Phone Number';
          _nickname = responseData['nickname'] ?? 'Unknown Nickname'; // Fetch and store nickname
        });
      } else {
        print('Error fetching user info: ${response.statusCode}'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user info')),
        );
      }
    } catch (error) {
      print('Exception occurred: $error'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user info')),
      );
    }
  }


  Future<void> _updateUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print('Updating user info with token: $token'); // Debug print

    try {
      final response = await http.put(
        Uri.parse('http://43.202.64.70:8864/api/users/userinfo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _name,
          'birthdate': _birthdateString, // Send birthdate as String
          'phoneNumber': _phoneNumber,
          'nickname': _nickname, // Send nickname
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated')),
        );
      } else {
        print('Error updating user info: ${response.statusCode}'); // Debug print
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile')),
        );
      }
    } catch (error) {
      print('Exception occurred: $error'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 100, // Profile icon size
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tap to change profile photo',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _buildDisplayField('Name', _name, editable: true),
                  SizedBox(height: 16),
                  _buildDisplayField(
                      'Birthdate',
                      _birthdateString.isNotEmpty ? _birthdateString : 'Not Set', // Display birthdate string
                      editable: true), // Display only
                  SizedBox(height: 16),
                  _buildDisplayField('Phone Number', _phoneNumber, editable: true),
                  SizedBox(height: 16),
                  _buildDisplayField('Nickname', _nickname, editable: true), // Add nickname field
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateUserInfo(); // Update user information
                      },
                      child: Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayField(String label, String value, {bool editable = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(fontSize: 16),
          ),
        ),
        if (editable) // Show edit button only for editable fields
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              if (label == 'Name') {
                // Handle name editing
                _showEditDialog('Name', _name, (newValue) {
                  setState(() {
                    _name = newValue;
                  });
                });
              } else if (label == 'Phone Number') {
                // Handle phone number editing
                _showEditDialog('Phone Number', _phoneNumber, (newValue) {
                  setState(() {
                    _phoneNumber = newValue;
                  });
                });
              } else if (label == 'Nickname') {
                // Handle nickname editing
                _showEditDialog('Nickname', _nickname, (newValue) {
                  setState(() {
                    _nickname = newValue;
                  });
                });
              }
            },
          ),
      ],
    );
  }

  void _showEditDialog(String label, String currentValue, Function(String) onSave) {
    final TextEditingController _controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $label'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: label),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSave(_controller.text);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
