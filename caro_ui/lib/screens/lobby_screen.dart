import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/game_service.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  LobbyScreen({super.key});

  final TextEditingController _nameController = TextEditingController(
    text: "Player",
  );
  final TextEditingController _roomIdController = TextEditingController();

  // Hàm mới để hiển thị Dialog
  void _showJoinRoomDialog(BuildContext context) {
    final gameService = context.read<GameService>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tham gia phòng"),
          content: TextField(
            controller: _roomIdController,
            decoration: const InputDecoration(hintText: "Nhập mã phòng..."),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                final roomId = _roomIdController.text;
                final playerName = _nameController.text;
                if (roomId.isNotEmpty && playerName.isNotEmpty) {
                  gameService.joinRoom(roomId, playerName);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Tham gia"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<GameService>();
    final isGameStarted = context.select<GameService, bool>(
      (service) => service.isGameStarted,
    );

    if (isGameStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.read<GameService>().myPlayerId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Phòng Chờ')),
      body:
          gameService.roomId == null
              ? _buildInitialView(context)
              : _buildLobbyView(context, gameService),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Chào mừng tới Caro Online!",
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Tên người chơi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nút tạo phòng
                ElevatedButton(
                  onPressed: () {
                    context.read<GameService>().createRoom(
                      _nameController.text,
                    );
                  },
                  child: const Text('Tạo Phòng Mới'),
                ),
                const SizedBox(width: 16),

                // NÚT THAM GIA PHÒNG MỚI
                OutlinedButton(
                  onPressed: () {
                    _showJoinRoomDialog(context);
                  },
                  child: const Text('Tham gia phòng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyView(BuildContext context, GameService gameService) {
    // Giữ nguyên không thay đổi
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "MÃ PHÒNG",
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        gameService.roomId!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: gameService.roomId!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép mã phòng!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "NGƯỜI CHƠI (${gameService.players.length}/4)",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: gameService.players.length,
              itemBuilder: (context, index) {
                final player = gameService.players[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${player.playerId + 1}'),
                    ),
                    title: Text(player.playerName),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Center(child: Text("Đang chờ đủ người chơi để bắt đầu...")),
          const SizedBox(height: 10),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
