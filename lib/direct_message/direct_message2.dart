import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 타임스탬프 포맷을 위한 패키지

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io('http://localhost:8864', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.emit('joinChatRoom', {
      'chatRoomId': widget.chatRoomId,
      'senderId': widget.userId,
      'receiverId': widget.receiverId,
    });

    socket.on('receiveMessage', _handleReceivedMessage);
    socket.on('existingMessages', _handleExistingMessages);
  }

  void _handleReceivedMessage(data) {
    // 수신한 메시지를 리스트에 추가
    final newMessage = {
      '_id': data['_id'] ?? '',
      'senderId': data['senderId'] ?? '',
      'message': data['message'] ?? '',
      'isMe': data['senderId'] == widget.userId,
      'timestamp': DateTime.tryParse(data['timestamp']) ?? DateTime.now(),
    };

    setState(() {
      _messages.add(newMessage);
    });
    _scrollToBottom();
  }

  void _handleExistingMessages(data) {
    setState(() {
      for (var message in data) {
        if (message != null) {
          final existingMessage = {
            '_id': message['_id'] ?? '',
            'senderId': message['senderId'] ?? '',
            'message': message['message'] ?? '',
            'isMe': message['senderId'] == widget.userId,
            'timestamp': message['timestamp'] != null
                ? DateTime.tryParse(message['timestamp']) ?? DateTime.now()
                : DateTime.now(),
          };

          // 중복 체크
          if (!_messages.any((msg) => msg['_id'] == existingMessage['_id'])) {
            _messages.add(existingMessage);
          }
        }
      }
      _scrollToBottom();
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      final messageData = {
        'chatRoomId': widget.chatRoomId,
        'senderId': widget.userId,
        'receiverId': widget.receiverId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 서버에 메시지 전송
      socket.emit('sendMessage', messageData);

      // 메시지를 서버로 보낸 후 리스트에 추가하지 않음
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    socket.off('receiveMessage', _handleReceivedMessage);
    socket.off('existingMessages', _handleExistingMessages);
    socket.emit('leaveChatRoom', {'chatRoomId': widget.chatRoomId});
    socket.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('jm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MM/dd').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Direct Message')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: _messages.map((message) {
                  final isMe = message['isMe'];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
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
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: isMe ? 10 : 0,
                            right: isMe ? 0 : 10,
                            top: 5,
                          ),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Text(
                              _formatTimestamp(message['timestamp']),
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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
