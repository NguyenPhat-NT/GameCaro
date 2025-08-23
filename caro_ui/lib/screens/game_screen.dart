// caro_ui/lib/screens/game_screen.dart

import 'dart:async';
import 'package:caro_ui/screens/lobby_screen.dart';
import 'package:flutter/material.dart';
import 'package:caro_ui/widgets/chat_drawer.dart';
import 'package:provider/provider.dart';

import '../services/game_service.dart';
import '../game_theme.dart';
import '../widgets/player_info_card.dart';
import '../widgets/game_board.dart'; // Đảm bảo dòng import này tồn tại
import '../models/player_model.dart';

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
  int _lastKnownDisconnectedCount = 0;
  // Lưu lại ID của người chơi vừa kết nối lại để hiển thị thông báo
  final Set<int> _justReconnectedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gameService = context.read<GameService>();
      _lastKnownCurrentPlayerId = gameService.currentPlayerId;
      _showTurnMessage(gameService);
    });
  }

  @override
  void dispose() {
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
      try {
        final currentPlayer = gameService.players.firstWhere(
          (p) => p.playerId == gameService.currentPlayerId,
        );
        _showOverlayMessage("Lượt của: ${currentPlayer.playerName}");
      } catch (e) {
        print(
          "Không tìm thấy người chơi có lượt đi: ${gameService.currentPlayerId}",
        );
      }
    }
  }

  void _showSurrenderMessage(GameService gameService) {
    if (gameService.surrenderedPlayerIds.isEmpty) return;
    final surrenderedId = gameService.surrenderedPlayerIds.last;
    try {
      final surrenderedPlayer = gameService.players.firstWhere(
        (p) => p.playerId == surrenderedId,
      );
      _showOverlayMessage("${surrenderedPlayer.playerName} đã đầu hàng");
    } catch (e) {
      print("Không tìm thấy người chơi đã đầu hàng: $surrenderedId");
    }
  }

  void _showDisconnectionMessage(
    GameService gameService, {
    required bool isDisconnect,
  }) {
    // Tìm người chơi vừa thay đổi trạng thái
    final previousDisconnectedIds =
        _justReconnectedPlayerIds.isEmpty
            ? gameService.disconnectedPlayerIds
            : gameService.disconnectedPlayerIds.union(
              _justReconnectedPlayerIds,
            );

    final currentDisconnectedIds = gameService.disconnectedPlayerIds;

    int changedPlayerId = -1;

    if (isDisconnect) {
      // Một người vừa mất kết nối
      changedPlayerId =
          currentDisconnectedIds.difference(previousDisconnectedIds).first;
    } else {
      // Một người vừa kết nối lại
      changedPlayerId =
          previousDisconnectedIds.difference(currentDisconnectedIds).first;
      _justReconnectedPlayerIds.add(changedPlayerId);
    }

    try {
      final player = gameService.players.firstWhere(
        (p) => p.playerId == changedPlayerId,
      );
      final message =
          isDisconnect
              ? "${player.playerName} đã mất kết nối."
              : "${player.playerName} đã kết nối lại.";
      _showOverlayMessage(message);
    } catch (e) {
      print(
        "Không tìm thấy người chơi vừa thay đổi trạng thái kết nối: $changedPlayerId",
      );
    }
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

    if (gameService.shouldReturnToLobby) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reset cờ hiệu để không bị lặp vô hạn
        context.read<GameService>().consumeReturnToLobbySignal();

        // Thay thế màn hình hiện tại bằng LobbyScreen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LobbyScreen()),
          );
        }
      });
    }

    if (_lastKnownCurrentPlayerId != gameService.currentPlayerId) {
      _lastKnownCurrentPlayerId = gameService.currentPlayerId;
      _showTurnMessage(gameService);
    }
    if (_lastKnownSurrenderedCount != gameService.surrenderedPlayerIds.length) {
      _lastKnownSurrenderedCount = gameService.surrenderedPlayerIds.length;
      _showSurrenderMessage(gameService);
    }
    if (_lastKnownDisconnectedCount <
        gameService.disconnectedPlayerIds.length) {
      _showDisconnectionMessage(gameService, isDisconnect: true);
    }
    // Kiểm tra người chơi kết nối lại
    else if (_lastKnownDisconnectedCount >
        gameService.disconnectedPlayerIds.length) {
      _showDisconnectionMessage(gameService, isDisconnect: false);
    }
    _lastKnownDisconnectedCount = gameService.disconnectedPlayerIds.length;

    if (gameService.players.isEmpty || myPlayerId == null) {
      return const Scaffold(
        backgroundColor: AppColors.parchment,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.woodFrame,
      endDrawer: const ChatDrawer(),
      body: SafeArea(
        child: Container(
          color: AppColors.parchment,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(80, 20, 80, 50),
                child: Center(
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
              ),
              _buildPlayerCorners(context, gameService),
              _GameControlButtons(onSurrenderPressed: _onSurrenderPressed),
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

    // Hàm phụ để tạo widget cho một người chơi
    Widget buildPlayerWidget(Player player, Alignment alignment) {
      // Xác định vị trí dựa trên alignment
      final position =
          (alignment == Alignment.topLeft)
              ? Positioned(
                top: 10,
                left: 10,
                child: _playerCard(player, currentPlayerId, surrenderedIds),
              )
              : (alignment == Alignment.topRight)
              ? Positioned(
                top: 10,
                right: 10,
                child: _playerCard(player, currentPlayerId, surrenderedIds),
              )
              : (alignment == Alignment.bottomLeft)
              ? Positioned(
                bottom: 55,
                left: 10,
                child: _playerCard(
                  player,
                  currentPlayerId,
                  surrenderedIds,
                  nameFirst: true,
                ),
              )
              : Positioned(
                bottom: 55,
                right: 10,
                child: _playerCard(
                  player,
                  currentPlayerId,
                  surrenderedIds,
                  nameFirst: true,
                ),
              );
      return position;
    }

    // Xác định các vị trí cho tối đa 4 người chơi
    final alignments = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    return Stack(
      children: [
        // Dùng vòng lặp để tạo widget cho mỗi người chơi có trong phòng
        for (int i = 0; i < players.length; i++)
          buildPlayerWidget(players[i], alignments[i]),
      ],
    );
  }

  Widget _playerCard(
    Player player,
    int? currentPlayerId,
    Set<int> surrenderedIds, {
    bool nameFirst = false,
  }) {
    final card = PlayerInfoCard(
      player: player,
      // SỬA LỖI: So sánh với playerId thực tế của người chơi
      isMyTurn: currentPlayerId == player.playerId,
      hasSurrendered: surrenderedIds.contains(player.playerId),
    );
    final name = Text(
      player.playerName,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
    );

    return Column(
      children:
          nameFirst
              ? [name, const SizedBox(height: 4), card]
              : [card, const SizedBox(height: 4), name],
    );
  }

  Widget _buildWinnerOverlay(BuildContext context) {
    final gameService = context.read<GameService>();
    String message;
    Player? winner;
    if (gameService.isDraw) {
      message = "HÒA CỜ!";
    } else if (gameService.winnerId != null && gameService.players.isNotEmpty) {
      try {
        winner = gameService.players.firstWhere(
          (p) => p.playerId == gameService.winnerId,
        );
        message = "${winner.playerName} đã chiến thắng!";
      } catch (e) {
        message = "Trận đấu kết thúc!";
      }
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

            // Nút Chơi lại
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _GameControlButtons extends StatelessWidget {
  final VoidCallback onSurrenderPressed;
  const _GameControlButtons({required this.onSurrenderPressed});

  @override
  Widget build(BuildContext context) {
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
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  tooltip: "Trò chuyện",
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    // BƯỚC 3: Đánh dấu đã đọc tin nhắn
                    context.read<GameService>().markChatAsRead();
                    // Mở ngăn kéo chat
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
                // BƯỚC 2: Hiển thị chấm đỏ nếu có tin nhắn chưa đọc
                if (gameService.hasUnreadMessages)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              tooltip: "Đầu hàng",
              icon: const Icon(Icons.flag_outlined),
              onPressed: onSurrenderPressed,
            ),
          ],
        ),
      ),
    );
  }
}
