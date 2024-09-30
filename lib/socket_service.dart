import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  SocketService() {
    socket = IO.io('http://localhost:8864', {
      'transports': ['websocket'],
      'autoConnect': true,
    });
  }

  void connect() {
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  // 소켓 이벤트 핸들링 메서드 추가
  void onConnect(Function callback) {
    socket.onConnect((_) => callback());
  }

  void onDisconnect(Function callback) {
    socket.onDisconnect((_) => callback());
  }

  // 다른 이벤트 리스너 메서드 추가
  void on(String event, Function callback) {
    socket.on(event, callback());
  }
}
