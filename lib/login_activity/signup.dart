import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _nicknameController = TextEditingController();

  String? _errorMessage; // 에러 메시지를 저장할 변수 추가

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _birthdateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (_formKey.currentState?.validate() ?? false) {
      // 비밀번호와 비밀번호 확인 비교
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = '비밀번호와 비밀번호 확인이 일치하지 않습니다.';
        });
        return;
      }
      if (_passwordController.text.length < 5) {
        setState(() {
          _errorMessage = '비밀번호는 5자리 이상으로 만들어주세요.';
        });
        return;
      }
      if (_nicknameController.text.length > 10) {
        setState(() {
          _errorMessage = '닉네임은 10자리 이내로 만들어주세요.';
        });
        return;
      }

      final response = await http.post(
        Uri.parse('http://43.202.64.70:8864/api/users/signup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': _nameController.text,
          'username': _usernameController.text,
          'birthdate': _birthdateController.text,
          'password': _passwordController.text,
          'phoneNumber': _phoneNumberController.text,
          'nickname': _nicknameController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('isLoggedIn', true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 성공')),
        );
        Navigator.pop(context);
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? '회원가입 실패'; // 서버에서 받은 에러 메시지 설정
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Text('회원가입', style: TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold)),
                SizedBox(height: 15),
                Text('사용자 정보를 입력하세요.', style: TextStyle(color: Colors.black, fontSize: 20)),
                SizedBox(height: 70),
                // Input fields with icons
                _buildTextField(_nameController, '이름', Icons.person),
                _buildTextField(_usernameController, '아이디', Icons.person_outline),
                _buildTextField(_birthdateController, '생일', Icons.calendar_today, keyboardType: TextInputType.datetime),
                _buildTextField(_passwordController, '비밀번호', Icons.lock, obscureText: true),
                _buildTextField(_confirmPasswordController, '비밀번호 확인', Icons.lock_outline, obscureText: true),
                _buildTextField(_phoneNumberController, '전화번호', Icons.phone, keyboardType: TextInputType.phone),
                _buildTextField(_nicknameController, '닉네임', Icons.star),
                if (_errorMessage != null) // 에러 메시지가 있을 경우에만 표시
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red), // 빨간 글자 스타일
                    ),
                  ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitData,
                  child: Text('회원가입', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF25c387), // 버튼 색상
                    padding: EdgeInsets.symmetric(vertical: 25), // 버튼
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 모서리 반경을 0으로 설정
                    ), // 패딩
                    textStyle: TextStyle(fontSize: 18), // 버튼 텍스트 크기
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon), // 아이콘 추가
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // 테두리 둥글게
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 2), // 클릭 시 테두리 색상을 회색으로 변경
          ),
          floatingLabelStyle: TextStyle(color: Colors.grey), // 포커스 시 라벨 색상을 회색으로 변경
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label을 입력해주세요.';
          }
          return null;
        },
      ),
    );
  }
}
