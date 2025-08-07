import 'package:caro_ui/services/network_service.dart';
import 'package:flutter/material.dart';
// Cần thiết cho việc sử dụng Socket sau này

// Giả định bạn sẽ có một màn hình phòng chờ (LobbyScreen) để chuyển đến
import '../screens/lobby_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  // Sử dụng TextEditingController để lấy giá trị từ TextField
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  // Biến để quản lý trạng thái đang kết nối, giúp hiển thị loading
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đặt giá trị mặc định từ tài liệu API để tiện cho việc test
    _ipController.text = '103.157.205.146'; // IP VPS từ tài liệu [cite: 5]
    _portController.text = '8888'; // Port từ tài liệu [cite: 6]
  }

  void _connectToServer() async {
    setState(() {
      _isLoading = true;
    });

    final String ip = _ipController.text;
    final int? port = int.tryParse(_portController.text);

    if (port == null) {
      // Hiển thị lỗi nếu port không hợp lệ
      _showErrorDialog("Lỗi", "Port phải là một con số.");
      setState(() {
        _isLoading = false;
      });
      return;
    }
    // Sử dụng Singleton để kết nối
    final networkService = NetworkService(); // Lấy thực thể duy nhất
    bool success = await networkService.connect(ip, port);

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LobbyScreen()),
        );
      }
    } else {
      _showErrorDialog(
        "Kết nối thất bại",
        "Không thể kết nối đến server. Vui lòng kiểm tra lại IP/Port và trạng thái server.",
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Đã hiểu"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    // Luôn dispose các controller khi widget bị hủy để giải phóng tài nguyên
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kết nối đến Server Caro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TextField cho địa chỉ IP
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: "Địa chỉ IP Server",
                hintText: "Ví dụ: 127.0.0.1",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // TextField cho Port
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: "Port",
                hintText: "Ví dụ: 8888",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // Nút bấm hoặc vòng tròn loading
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _connectToServer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("Kết nối"),
                ),
          ],
        ),
      ),
    );
  }
}
