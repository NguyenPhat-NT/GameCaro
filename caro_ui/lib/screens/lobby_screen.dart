// File: caro_ui/lib/screens/lobby_screen.dart
import 'package:caro_ui/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:caro_ui/services/connection_screen.dart';
import '../game_theme.dart';
import '../models/player_model.dart';
import '../services/game_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart'; // <-- Đảm bảo có import này
import '../widgets/chat_drawer.dart';
import 'game_screen.dart';
import 'room_list_screen.dart';

class LobbyScreen extends StatefulWidget {
  LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  bool _reconnectDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlayerName();
      _checkAndPromptForReconnect();
    });
  }

  Future<void> _loadPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    final playerName = prefs.getString('playerName') ?? '';
    if (mounted) {
      setState(() {
        _nameController.text = playerName;
      });
    }
  }

  Future<void> _savePlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    final playerName = _nameController.text.trim();
    if (playerName.isNotEmpty) {
      await prefs.setString('playerName', playerName);
    }
  }

  Future<void> _checkAndPromptForReconnect() async {
    if (!mounted || _reconnectDialogShown) return;
    final gameService = context.read<GameService>();
    if (gameService.consumeFirstLobbyLoad()) {
      final dbService = DatabaseService();
      final session = await dbService.getSession();
      if (session != null) {
        setState(() {
          _reconnectDialogShown = true;
        });
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: AppColors.parchment,
              title: const Text("Tiếp tục trận đấu?"),
              content: const Text(
                "Chúng tôi tìm thấy một trận đấu bạn đang tham gia. Bạn có muốn kết nối lại không?",
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Hủy"),
                  onPressed: () {
                    SoundService().playClickSound(); // <-- THÊM ÂM THANH
                    dbService.deleteSession();
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text("Kết nối lại"),
                  onPressed: () {
                    SoundService().playClickSound(); // <-- THÊM ÂM THANH
                    final roomId = session['roomId'] as String;
                    final sessionToken = session['sessionToken'] as String;
                    final playerName = session['myPlayerName'] as String;
                    gameService.reconnectToGame(
                      roomId,
                      sessionToken,
                      playerName,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _showJoinRoomDialog(BuildContext context) {
    final gameService = context.read<GameService>();
    final roomIdController = TextEditingController();
    final playerName = context.read<GameService>().myPlayerName ?? "Player";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.parchment,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: roomIdController,
                          decoration: const InputDecoration(
                            labelText: "Nhập mã phòng...",
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          SoundService().playClickSound(); // <-- THÊM ÂM THANH
                          final roomId =
                              roomIdController.text.trim().toUpperCase();
                          if (roomId.isNotEmpty && playerName.isNotEmpty) {
                            gameService.joinRoom(roomId, playerName);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text("Tham gia"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      SoundService().playClickSound(); // <-- THÊM ÂM THANH
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Hủy",
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        actions: [
          if (!isInLobby)
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu), // Icon 3 gạch
                  tooltip: 'Danh sách phòng',
                  onPressed: () {
                    SoundService().playClickSound(); // <-- THÊM ÂM THANH
                    final playerName = _nameController.text.trim();
                    if (playerName.isNotEmpty) {
                      _savePlayerName();
                      gameService.setMyPlayerName(playerName);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RoomListScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên người chơi trước.'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
      endDrawer: const ChatDrawer(),
      body: isInLobby ? _buildLobbyView(context) : _buildInitialView(context),
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
            Text(
              "Chào mừng tới Caro Online!",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Tên người chơi",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _savePlayerName(),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    SoundService().playClickSound();
                    final playerName = _nameController.text.trim();
                    if (playerName.isNotEmpty) {
                      _savePlayerName();
                      gameService.createRoom(playerName);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng nhập tên trước khi tạo phòng.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Tạo Phòng Mới'),
                ),
                ElevatedButton(
                  onPressed: () {
                    SoundService().playClickSound();
                    final playerName = _nameController.text.trim();
                    if (playerName.isNotEmpty) {
                      _savePlayerName();
                      gameService.findMatch(playerName);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng nhập tên trước khi tìm trận.',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.highlight,
                  ),
                  child: const Text('Tìm trận'),
                ),
                OutlinedButton(
                  onPressed: () {
                    SoundService().playClickSound();
                    final playerName = _nameController.text.trim();
                    if (playerName.isNotEmpty) {
                      _savePlayerName();
                      _showJoinRoomDialog(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng nhập tên trước khi tham gia phòng.',
                          ),
                        ),
                      );
                    }
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

  Widget _buildLobbyView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
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
          const VerticalDivider(
            color: AppColors.woodFrame,
            thickness: 2,
            indent: 20,
            endIndent: 20,
          ),
          Expanded(flex: 3, child: _buildPlayerList(context)),
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
                Text(
                  gameService.roomId!,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                SoundService().playClickSound(); // <-- THÊM ÂM THANH
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
        Text(
          "NGƯỜI CHƠI (${players.length}/4)",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        Expanded(
          child:
              players.isEmpty
                  ? const Center(child: Text("Chưa có ai trong phòng."))
                  : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return Card(
                        color: AppColors.parchment.withOpacity(0.7),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: player.color,
                            child: Text('${player.playerId + 1}'),
                          ),
                          title: Text(
                            player.playerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing:
                              player.isHost
                                  ? const Icon(
                                    Icons.star,
                                    color: AppColors.highlight,
                                  )
                                  : null,
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Trò chuyện"),
              onPressed: () {
                SoundService().playClickSound(); // <-- THÊM ÂM THANH
                context.read<GameService>().markChatAsRead();
                Scaffold.of(context).openEndDrawer();
              },
            ),
            if (gameService.hasUnreadMessages)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.parchment, width: 2),
                  ),
                ),
              ),
          ],
        ),
        if (isHost && players.length >= 2)
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text("Bắt đầu"),
            onPressed: () {
              SoundService().playClickSound(); // <-- THÊM ÂM THANH
              gameService.startGameEarly();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ElevatedButton.icon(
          icon: const Icon(Icons.exit_to_app),
          label: const Text("Rời phòng"),
          onPressed: () {
            SoundService().playClickSound(); // <-- THÊM ÂM THANH
            gameService.leaveRoom();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ],
    );
  }
}
