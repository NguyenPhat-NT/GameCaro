// caro_ui/lib/screens/game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:caro_ui/widgets/chat_drawer.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/game_service.dart';
import '../game_theme.dart';
import '../widgets/player_info_card.dart';
import '../widgets/game_board.dart';
import '../models/player_model.dart';
import '../services/connection_screen.dart';
import '../screens/lobby_screen.dart';
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _overlayMessage;
  Timer? _overlayTimer;
  int? _lastKnownCurrentPlayerId;
  int _lastKnownSurrenderedCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameService = context.read<GameService>();
      _lastKnownCurrentPlayerId = gameService.currentPlayerId;
      _showTurnMessage(gameService);
    });
  }

  @override
  void dispose() {
    // --- BƯỚC 2.2: Xóa các dòng sau ---
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
    _overlayTimer?.cancel();
    super.dispose();
  }
  void _showOverlayMessage(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (mounted) {
      _overlayTimer?.cancel();
      setState(() {
        _overlayMessage = message;
      });
      _overlayTimer = Timer(duration, () {
        if (mounted) {
          setState(() {
            _overlayMessage = null;
          });
        }
      });
    }
  }

  void _showTurnMessage(GameService gameService) {
    if (gameService.currentPlayerId != null && gameService.players.isNotEmpty) {
      final currentPlayer = gameService.players.firstWhere(
        (p) => p.playerId == gameService.currentPlayerId,
      );
      _showOverlayMessage("Lượt của: ${currentPlayer.playerName}");
    }
  }

  void _showSurrenderMessage(GameService gameService) {
    if (gameService.surrenderedPlayerIds.isEmpty) return;
    final surrenderedId = gameService.surrenderedPlayerIds.last;
    final surrenderedPlayer = gameService.players.firstWhere(
      (p) => p.playerId == surrenderedId,
    );
    _showOverlayMessage("${surrenderedPlayer.playerName} đã đầu hàng");
  }

  void _onSurrenderPressed() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.parchment,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Xác nhận",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: Text(
            "Bạn có chắc chắn muốn đầu hàng không?",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Hủy",
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                "Đầu hàng",
                style: TextStyle(
                  color: AppColors.playerColors[0],
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<GameService>().surrender();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<GameService>();
    final myPlayerId = gameService.myPlayerId;

    if (_lastKnownCurrentPlayerId != gameService.currentPlayerId) {
      _lastKnownCurrentPlayerId = gameService.currentPlayerId;
      _showTurnMessage(gameService);
    }
    if (_lastKnownSurrenderedCount != gameService.surrenderedPlayerIds.length) {
      _lastKnownSurrenderedCount = gameService.surrenderedPlayerIds.length;
      _showSurrenderMessage(gameService);
    }

    if (gameService.players.isEmpty || myPlayerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.parchment,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Đang tải dữ liệu trận đấu..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.woodFrame,
      // --- THÊM MỚI: Thêm ngăn kéo chat vào Scaffold ---
      endDrawer: const ChatDrawer(),
      body: SafeArea(
        child: Container(
          color: AppColors.parchment,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(80, 20, 80, 50),
                child: GameBoard(
                  width: gameService.boardSize,
                  height: gameService.boardSize,
                  moves: gameService.moves,
                  players: gameService.players,
                  onMoveMade: (x, y) {
                    if (gameService.currentPlayerId == myPlayerId) {
                      gameService.makeMove(x, y);
                    }
                  },
                ),
              ),
              _buildPlayerCorners(context, gameService),
              // --- THAY ĐỔI: Sử dụng widget mới cho các nút điều khiển ---
              const _GameControlButtons(),
              _buildOverlayIndicator(),
              if (gameService.winnerId != null || gameService.isDraw)
                _buildWinnerOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayIndicator() {
    return Center(
      child: AnimatedOpacity(
        opacity: _overlayMessage != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.ink.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _overlayMessage ?? '',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.parchment,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCorners(BuildContext context, GameService gameService) {
    final players = gameService.players;
    final currentPlayerId = gameService.currentPlayerId;
    final surrenderedIds = gameService.surrenderedPlayerIds;

    // Hàm trợ giúp để tạo widget tên người chơi
    Widget _buildPlayerName(Player player) {
      return Text(
        player.playerName,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      );
    }

    return Stack(
      children: [
        if (players.length > 0)
          Positioned(
            top: 10,
            left: 10,
            child: Column(
              children: [
                PlayerInfoCard(
                  player: players[0],
                  isMyTurn: currentPlayerId == 0,
                  hasSurrendered: surrenderedIds.contains(0),
                ),
                const SizedBox(height: 4),
                _buildPlayerName(players[0]),
              ],
            ),
          ),
        if (players.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                PlayerInfoCard(
                  player: players[1],
                  isMyTurn: currentPlayerId == 1,
                  hasSurrendered: surrenderedIds.contains(1),
                ),
                const SizedBox(height: 4),
                _buildPlayerName(players[1]),
              ],
            ),
          ),
        if (players.length > 2)
          Positioned(
            bottom: 55,
            left: 10,
            child: Column(
              children: [
                _buildPlayerName(players[2]),
                const SizedBox(height: 4),
                PlayerInfoCard(
                  player: players[2],
                  isMyTurn: currentPlayerId == 2,
                  hasSurrendered: surrenderedIds.contains(2),
                ),
              ],
            ),
          ),
        if (players.length > 3)
          Positioned(
            bottom: 55,
            right: 10,
            child: Column(
              children: [
                _buildPlayerName(players[3]),
                const SizedBox(height: 4),
                PlayerInfoCard(
                  player: players[3],
                  isMyTurn: currentPlayerId == 3,
                  hasSurrendered: surrenderedIds.contains(3),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomUtilityBar(BuildContext context, GameService gameService) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.parchment.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Phòng: ${gameService.roomId ?? '...'}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 12),
            Container(
              width: 1.5,
              height: 20,
              color: AppColors.ink.withOpacity(0.4),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: "Trò chuyện",
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {},
            ),
            IconButton(
              tooltip: "Đầu hàng",
              icon: const Icon(Icons.flag_outlined),
              onPressed: _onSurrenderPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerOverlay(BuildContext context) {
    final gameService = context.read<GameService>();
    String message;
    Player? winner;
    if (gameService.isDraw) {
      message = "HÒA CỜ!";
    } else if (gameService.winnerId != null && gameService.players.isNotEmpty) {
      winner = gameService.players.firstWhere(
        (p) => p.playerId == gameService.winnerId,
        orElse: () => gameService.players.first,
      );
      message = "${winner.playerName} đã chiến thắng!";
    } else {
      message = "Trận đấu kết thúc!";
    }
    return Container(
      color: AppColors.ink.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.highlight,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                print("UI: Người dùng bấm nút Game Mới");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.parchment,
              ),
              child: Text(
                "Game Mới",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                print("UI: Người dùng bấm nút Thoát Phòng");
                context.read<GameService>().resetStateForNewConnection();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LobbyScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text(
                "Thoát Phòng",
                style: TextStyle(color: AppColors.parchment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _GameControlButtons extends StatelessWidget {
  const _GameControlButtons();

  @override
  Widget build(BuildContext context) {
    // Context ở đây đã nằm "bên dưới" Scaffold, nên gọi Scaffold.of() sẽ thành công
    final gameService = context.read<GameService>();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.parchment.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Phòng: ${gameService.roomId ?? '...'}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 12),
            Container(
              width: 1.5,
              height: 20,
              color: AppColors.ink.withOpacity(0.4),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: "Trò chuyện",
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                // Lệnh này giờ sẽ hoạt động bình thường
                Scaffold.of(context).openEndDrawer();
              },
            ),
            IconButton(
              tooltip: "Đầu hàng",
              icon: const Icon(Icons.flag_outlined),
              onPressed: () {
                // Cần truy cập _onSurrenderPressed, chúng ta có thể làm như sau:
                // Tìm state của _GameScreenState và gọi hàm
                context.findAncestorStateOfType<_GameScreenState>()?._onSurrenderPressed();
              },
            ),
          ],
        ),
      ),
    );
  }
}