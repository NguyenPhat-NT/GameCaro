// File: caro_ui/lib/screens/lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:caro_ui/services/connection_screen.dart';
import '../game_theme.dart';
import '../models/player_model.dart';
import '../services/game_service.dart';
import '../widgets/chat_drawer.dart';
import 'game_screen.dart';

class LobbyScreen extends StatelessWidget {
  LobbyScreen({super.key});

  final TextEditingController _nameController = TextEditingController(text: "Player");
  final TextEditingController _roomIdController = TextEditingController();

  void _showJoinRoomDialog(BuildContext context) {
    final gameService = context.read<GameService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.parchment,
        title: const Text("Tham gia phòng"),
        content: TextField(
          controller: _roomIdController,
          decoration: const InputDecoration(hintText: "Nhập mã phòng..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy", style: TextStyle(color: AppColors.ink)),
          ),
          ElevatedButton(
            onPressed: () {
              final roomId = _roomIdController.text.trim().toUpperCase();
              final playerName = _nameController.text.trim();
              if (roomId.isNotEmpty && playerName.isNotEmpty) {
                gameService.joinRoom(roomId, playerName);
                Navigator.of(context).pop();
              }
            },
            child: const Text("Tham gia"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<GameService>();

    if (gameService.isGameStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name != '/game') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const GameScreen(),
              settings: const RouteSettings(name: '/game'),
            ),
          );
        }
      });
    }

    if (gameService.shouldNavigateHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ConnectionScreen()),
          (Route<dynamic> route) => false,
        );
      });
    }

    final bool isInLobby = gameService.roomId != null;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.woodFrame,
        elevation: 4,
        title: Text(
          isInLobby ? 'Phòng Chờ' : 'Trang Chủ',
          style: textTheme.headlineSmall?.copyWith(color: AppColors.parchment),
        ),
        automaticallyImplyLeading: false,
      ),
      endDrawer: const ChatDrawer(),
      body: isInLobby
          ? _buildLobbyView(context)
          : _buildInitialView(context),
    );
  }

  Widget _buildInitialView(BuildContext context) {
    final gameService = context.read<GameService>();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Chào mừng tới Caro Online!", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Tên người chơi", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => gameService.createRoom(_nameController.text.trim()),
                  child: const Text('Tạo Phòng Mới'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => _showJoinRoomDialog(context),
                  child: const Text('Tham gia phòng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyView(BuildContext context) {
    // --- THAY ĐỔI: Bọc cột trái trong SingleChildScrollView ---
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView( // <--- Bọc ở đây
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoomInfoCard(context),
                  const SizedBox(height: 24),
                  const _LobbyActionButtons(),
                ],
              ),
            ),
          ),
          const VerticalDivider(color: AppColors.woodFrame, thickness: 2, indent: 20, endIndent: 20),
          Expanded(
            flex: 3,
            child: _buildPlayerList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard(BuildContext context) {
    final gameService = context.watch<GameService>();
    return Card(
      color: AppColors.parchment,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text("MÃ PHÒNG", style: TextStyle(color: Colors.grey)),
                Text(gameService.roomId!, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: gameService.roomId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã phòng!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList(BuildContext context) {
    final gameService = context.watch<GameService>();
    final players = gameService.players;
    return Column(
      children: [
        Text("NGƯỜI CHƠI (${players.length}/4)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        Expanded(
          child: players.isEmpty
              ? const Center(child: Text("Chưa có ai trong phòng."))
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return Card(
                      color: AppColors.parchment.withOpacity(0.7),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: player.color, child: Text('${player.playerId + 1}')),
                        title: Text(player.playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: player.isHost ? const Icon(Icons.star, color: AppColors.highlight) : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LobbyActionButtons extends StatelessWidget {
  const _LobbyActionButtons();

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<GameService>();
    final isHost = gameService.myPlayerId == 0;
    final players = gameService.players;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.0,
      runSpacing: 12.0,
      direction: Axis.vertical,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text("Trò chuyện"),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
        if (isHost && players.length >= 2)
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text("Bắt đầu"),
            onPressed: () => gameService.startGameEarly(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ElevatedButton.icon(
          icon: const Icon(Icons.exit_to_app),
          label: const Text("Rời phòng"),
          onPressed: () => gameService.leaveRoom(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }
}