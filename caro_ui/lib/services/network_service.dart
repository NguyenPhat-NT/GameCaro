import 'dart:io';
import 'dart:convert';
import 'dart:async';

class NetworkService {
  Socket? _socket;
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  Function? onDisconnected; // Callback để thông báo mất kết nối

  Stream<String> get messages => _messageController.stream;

  Future<bool> connect(String ip, int port) async {
    try {
      print('Đang kết nối đến $ip:$port...');
      _socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      print('Kết nối thành công!');

      String buffer = '';
      _socket!.listen(
        (data) {
          buffer += utf8.decode(data);
          while (buffer.contains('\n')) {
            int newlineIndex = buffer.indexOf('\n');
            String message = buffer.substring(0, newlineIndex);
            buffer = buffer.substring(newlineIndex + 1);

            if (message.isNotEmpty) {
              print('Nhận từ Server: $message');
              _messageController.add(message);
            }
          }
        },
        onError: (error) {
          print('Lỗi kết nối: $error');
          disconnect();
          onDisconnected?.call(error.toString());
        },
        onDone: () {
          print('Server đã đóng kết nối.');
          disconnect();
          onDisconnected?.call('Server đã đóng kết nối.');
        },
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      print('Không thể kết nối: $e');
      return false;
    }
  }

  void sendMessage(String message) {
    if (_socket != null) {
      print('Gửi đến Server: $message');
      _socket!.writeln(message);
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
  }
}
