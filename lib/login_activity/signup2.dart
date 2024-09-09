import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Signup2Screen extends StatefulWidget {
  @override
  _Signup2ScreenState createState() => _Signup2ScreenState();
}

class _Signup2ScreenState extends State<Signup2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  Map<String, String>? _signup1Data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Signup1Screen에서 전달된 데이터 받기
    _signup1Data = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (_formKey.currentState?.validate() ?? false) {
      final response = await http.post(
        Uri.parse('http://localhost:8864/api/users/signup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': _signup1Data?['name'] ?? '',
          'username': _signup1Data?['username'] ?? '',
          'birthdate': _signup1Data?['birthdate'] ?? '',
          'password': _signup1Data?['password'] ?? '',
          'phoneNumber': _phoneNumberController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to signup')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
