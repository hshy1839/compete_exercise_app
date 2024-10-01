import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class DirectMessage2 extends StatefulWidget {
  final String chatRoomId;
  final String userId; // 본인 ID
  final String receiverId; // 상대방 ID

  DirectMessage2({required this.chatRoomId, required this.userId, required this.receiverId});

  @override
  _DirectMessage2State createState() => _DirectMessage2State();
}

class _DirectMessage2State extends State<DirectMessage2> {
  late IO.Socket socket;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  // Socket.IO 연결
  void _connectSocket() {
    socket = IO.io('http://localhost:8864', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    // 채팅방 참여
    socket.emit('joinChatRoom', {
      'senderId': widget.userId,
      'receiverId': widget.receiverId,
    });

    // 서버에서 채팅방 참여 응답을 받음
    socket.on('joinedChatRoom', (data) {
      print('채팅방에 참여했습니다. ID: ${data['chatRoomId']}');
    });

    // 서버에서 수신한 메시지 처리
    socket.on('receiveMessage', (data) {
      setState(() {
        _messages.add({
          'senderId': data['senderId'],
          'message': data['message'],
        });
      });
    });
  }

  // 메시지 전송
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      socket.emit('sendMessage', {
        'chatRoomId': widget.chatRoomId,
        'senderId': widget.userId,
        'receiverId': widget.receiverId, // receiverId 추가
        'message': message,
      });

      setState(() {
        _messages.add({
          'senderId': widget.userId,
          'message': message,
        });
        _messageController.clear();
      });
    }
  }

  @override
  void dispose() {
    // 채팅방 나가기 이벤트를 서버로 보냄
    socket.emit('leaveChatRoom', {'chatRoomId': widget.chatRoomId});

    // 소켓 연결 해제
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Direct Message')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message['message']),
                  subtitle: Text(message['senderId'] == widget.userId ? 'You' : 'Other'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
