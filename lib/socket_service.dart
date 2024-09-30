import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends ChangeNotifier {
  late IO.Socket socket;

  SocketService() {
    socket = IO.io('http://localhost:8864', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('소켓 연결됨');
      notifyListeners();
    });

    socket.onDisconnect((_) {
      print('소켓 연결 해제됨');
      notifyListeners();
    });
  }

  void connect() {
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  // 이벤트 리스너 메서드 추가
  void on(String event, Function callback) {
    socket.on(event, callback());
  }

  void onConnect(Function callback) {
    socket.onConnect((_) => callback());
  }

  void onDisconnect(Function callback) {
    socket.onDisconnect((_) => callback());
  }

}
