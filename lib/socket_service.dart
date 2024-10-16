import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class SocketService extends ChangeNotifier {
  late IO.Socket socket;

  SocketService() {
    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io('http://localhost:8864', IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect() // 자동 연결 비활성화
        .build());

    socket.onConnect((_) {
      print('Socket connected');
      notifyListeners();
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
      notifyListeners();
    });

    socket.on('connect_error', (data) {
      print('Socket connection error: $data');
    });
  }

  void connect() {
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void off(String event, [Function(dynamic)? callback]) {
    socket.off(event, callback);
  }
  @override
  void dispose() {
    socket.disconnect(); // 소켓 연결 해제
    super.dispose();
  }

  bool get isConnected => socket.connected; // Add a getter for connection status
}
