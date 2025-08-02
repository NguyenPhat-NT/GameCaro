import 'dart:io';
import 'dart:convert';
import 'dart:async';

class NetworkService {
  // 1. Tạo một thực thể static, private
  static final NetworkService _instance = NetworkService._internal();

  // 2. Tạo một factory constructor để trả về thực thể duy nhất ở trên
  factory NetworkService() {
    return _instance;
  }

  // 3. Tạo một private constructor (hàm khởi tạo riêng tư)
  NetworkService._internal();

  Socket? _socket;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Function(String)? onDisconnected;

  // Sửa kiểu dữ liệu của Stream để làm việc trực tiếp với JSON (Map)
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  Future<bool> connect(String ip, int port) async {
    try {
      if (_socket != null) {
        print("Đã có kết nối, ngắt kết nối cũ trước khi tạo mới.");
        await disconnect();
      }

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
          // Server có thể gửi nhiều JSON trong một gói tin
          // Lặp để xử lý tất cả
          while (true) {
            try {
              // Tìm vị trí kết thúc của một đối tượng JSON hoàn chỉnh
              final jsonEnd = _findJsonEnd(buffer);
              if (jsonEnd == -1) break; // Không tìm thấy JSON hoàn chỉnh

              final messageString = buffer.substring(0, jsonEnd);
              buffer = buffer.substring(jsonEnd);

              if (messageString.isNotEmpty) {
                final jsonMessage =
                    jsonDecode(messageString) as Map<String, dynamic>;
                print('Nhận từ Server: $jsonMessage');
                _messageController.add(jsonMessage);
              }
            } catch (e) {
              // Nếu JSON chưa hoàn chỉnh, vòng lặp sẽ dừng và đợi thêm dữ liệu
              // print("JSON chưa hoàn chỉnh, đang đợi thêm... Lỗi: $e");
              break;
            }
          }
        },
        onError: (error) {
          print('Lỗi kết nối: $error');
          onDisconnected?.call(error.toString());
          disconnect();
        },
        onDone: () {
          print('Server đã đóng kết nối.');
          onDisconnected?.call('Server đã đóng kết nối.');
          disconnect();
        },
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      print('Không thể kết nối: $e');
      return false;
    }
  }

  // Hàm helper để tìm vị trí kết thúc của một JSON object
  int _findJsonEnd(String input) {
    int braceCount = 0;
    bool inString = false;
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"' && (i == 0 || input[i - 1] != '\\')) {
        inString = !inString;
      }
      if (!inString) {
        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;
        }
      }
      if (braceCount == 0 && i > 0) {
        return i + 1;
      }
    }
    return -1; // Không tìm thấy
  }

  // Cải tiến hàm này để gửi đi đối tượng JSON
  void send(String type, Map<String, dynamic> payload) {
    if (_socket != null) {
      final message = {"Type": type, "Payload": payload};
      final messageString = jsonEncode(message);
      print('Gửi đến Server: $messageString');
      _socket!.write(messageString); // Sử dụng write thay vì writeln
    }
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket?.destroy();
    _socket = null;
  }
}
