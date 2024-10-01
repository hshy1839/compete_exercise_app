import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

class DirectMessage2 extends StatefulWidget {
  final String chatRoomId;
  final String userId; // 본인 ID
  final String receiverId; // 상대방 ID

  DirectMessage2({
    required this.chatRoomId,
    required this.userId,
    required this.receiverId,
  });

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
      'chatRoomId': widget.chatRoomId,
      'senderId': widget.userId,
      'receiverId': widget.receiverId,
    });

    // 서버에서 수신한 메시지 처리
    socket.on('receiveMessage', _handleReceivedMessage);

    // 서버에서 기존 메시지 수신
    socket.on('existingMessages', _handleExistingMessages);
  }

  // 수신한 메시지 처리
  void _handleReceivedMessage(data) {
    final newMessage = {
      'senderId': data['senderId'],
      'message': data['message'],
      'isMe': data['senderId'] == widget.userId, // 추가된 부분
    };

    // 중복 체크
    if (!_messages.any((msg) =>
    msg['message'] == newMessage['message'] &&
        msg['senderId'] == newMessage['senderId'])) {
      setState(() {
        _messages.add(newMessage);
      });
    }
  }

  // 기존 메시지 처리
  void _handleExistingMessages(data) {
    setState(() {
      for (var message in data) {
        final existingMessage = {
          'senderId': message['senderId'],
          'message': message['message'],
          'isMe': message['senderId'] == widget.userId, // 비교
        };

        // 중복 체크
        if (!_messages.any((msg) =>
        msg['message'] == existingMessage['message'] &&
            msg['senderId'] == existingMessage['senderId'])) {
          _messages.add(existingMessage);
        }
      }
    });
  }

  // 메시지 전송
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      socket.emit('sendMessage', {
        'chatRoomId': widget.chatRoomId,
        'senderId': widget.userId,
        'receiverId': widget.receiverId,
        'message': message,
      });

      setState(() {
        _messages.add({
          'senderId': widget.userId,
          'message': message,
          'isMe': true, // 실시간 메시지의 경우 true로 설정
        });
        _messageController.clear(); // 메시지 전송 후 입력 필드 비우기
      });
    }
  }

  @override
  void dispose() {
    // 이벤트 리스너 제거
    socket.off('receiveMessage', _handleReceivedMessage);
    socket.off('existingMessages', _handleExistingMessages);

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
                final isMe = message['isMe']; // isMe 속성을 사용하여 구분

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[400] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
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
