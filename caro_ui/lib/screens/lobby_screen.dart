import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../screens/game_screen.dart';
import 'package:provider/provider.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  void _createRoom() {
    if (_nameController.text.isEmpty) {
      // Hiển thị lỗi nếu chưa nhập tên
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên của bạn')),
      );
      return;
    }
    setState(() => _isLoading = true);
    // Gọi hàm từ GameService
    context.read<GameService>().connectAndCreateRoom(_nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái kết nối từ GameService
    final isConnected = context.watch<GameService>().isConnected;
    final errorMessage = context.watch<GameService>().errorMessage;

    // Nếu kết nối thành công, chuyển đến màn hình game
    if (isConnected) {
      // Dùng postFrameCallback để tránh lỗi setState trong lúc build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameScreen()),
        );
      });
    }

    // Nếu có lỗi, dừng loading
    if (errorMessage != null && _isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      });
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Game Caro 4 Người",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên của bạn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _createRoom,
                    child: const Text('Tạo Phòng Mới'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
