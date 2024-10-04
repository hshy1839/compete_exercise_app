import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../socket_service.dart'; // Ensure this import is correct

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
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final socketService = Provider.of<SocketService>(context, listen: false);

    // Join the chat room
    socketService.emit('joinChatRoom', {
      'chatRoomId': widget.chatRoomId,
      'senderId': widget.userId,
    });

    socketService.on('receiveMessage', _handleReceivedMessage);
    socketService.on('existingMessages', _handleExistingMessages);
  }

  void _handleReceivedMessage(data) {
    if (!mounted || data == null) return; // mounted 체크 추가

    try {
      final newMessage = {
        '_id': data['_id'] ?? '',
        'senderId': data['senderId'] ?? '',
        'message': data['message'] ?? '',
        'isMe': data['senderId'] == widget.userId,
        'timestamp': DateTime.tryParse(data['timestamp']) ?? DateTime.now(),
      };

      if (!_messages.any((msg) => msg['_id'] == newMessage['_id'])) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error handling received message: $e');
    }
  }

  void _handleExistingMessages(data) {
    if (data == null || !mounted) return;
    try {
      final newMessages = data.map((message) {
        return {
          '_id': message['_id'] ?? '',
          'senderId': message['senderId'] ?? '',
          'message': message['message'] ?? '',
          'isMe': message['senderId'] == widget.userId,
          'timestamp': message['timestamp'] != null
              ? DateTime.tryParse(message['timestamp']) ?? DateTime.now()
              : DateTime.now(),
        };
      }).toList();

      // Avoid duplicates
      setState(() {
        for (var existingMessage in newMessages) {
          if (!_messages.any((msg) => msg['_id'] == existingMessage['_id'])) {
            _messages.add(existingMessage);
          }
        }
        _scrollToBottom();
      });
    } catch (e) {
      print('Error handling existing messages: $e');
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      final messageData = {
        'chatRoomId': widget.chatRoomId,
        'senderId': widget.userId,
        'receiverId': widget.receiverId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      socketService.emit('sendMessage', messageData);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 현재 ScrollController가 연결되어 있는지 다시 확인
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.off('receiveMessage', _handleReceivedMessage);
    socketService.off('existingMessages', _handleExistingMessages);
    _leaveChatRoom(); // Leave chat room
    super.dispose();
  }

  void _leaveChatRoom() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.emit('leaveChatRoom', {'chatRoomId': widget.chatRoomId});
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
      appBar: AppBar(
        title: Text('Direct Message'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // 소켓 이벤트 해제는 dispose에서 처리하므로, 여기서 단순히 Navigator.pop만 호출합니다.
            Navigator.pop(context); // 이전 페이지로 돌아가기
          },
        ),
      ),
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
