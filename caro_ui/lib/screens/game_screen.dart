// caro_ui/lib/screens/game_screen.dart

import 'dart:async';
import 'package:caro_ui/screens/lobby_screen.dart';
import 'package:flutter/material.dart';
import 'package:caro_ui/widgets/chat_drawer.dart';
import 'package:provider/provider.dart';
import '../services/sound_service.dart';
import '../services/game_service.dart';
import '../game_theme.dart';
import '../widgets/player_info_card.dart';
import '../widgets/game_board.dart';
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
  final Set<int> _justReconnectedPlayerIds = {};

  @override
  void initState() {
    super.initState();

    SoundService().playBgm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gameService = context.read<GameService>();
      _lastKnownCurrentPlayerId = gameService.currentPlayerId;
      _showTurnMessage(gameService);
    });
  }

  @override
  void dispose() {
    SoundService().stopBgm();

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
        // Lỗi không tìm thấy người chơi
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
      // Lỗi không tìm thấy
    }
  }

  void _showDisconnectionMessage(
    GameService gameService, {
    required bool isDisconnect,
  }) {
    final previousDisconnectedIds =
        _justReconnectedPlayerIds.isEmpty
            ? gameService.disconnectedPlayerIds
            : gameService.disconnectedPlayerIds.union(
              _justReconnectedPlayerIds,
            );
    final currentDisconnectedIds = gameService.disconnectedPlayerIds;
    int changedPlayerId = -1;
    if (isDisconnect) {
      changedPlayerId =
          currentDisconnectedIds.difference(previousDisconnectedIds).first;
    } else {
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
      // Lỗi không tìm thấy
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
        context.read<GameService>().consumeReturnToLobbySignal();
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
    } else if (_lastKnownDisconnectedCount >
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

              // *** THAY ĐỔI: GỌI WIDGET HIỆU ỨNG MỚI ***
              if (gameService.winnerId != null || gameService.isDraw)
                WinnerOverlay(),
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
    // ... code widget này giữ nguyên không đổi ...
    final players = gameService.players;
    final currentPlayerId = gameService.currentPlayerId;
    final surrenderedIds = gameService.surrenderedPlayerIds;

    Widget buildPlayerWidget(Player player, Alignment alignment) {
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

    final alignments = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    return Stack(
      children: [
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
    // ... code widget này giữ nguyên không đổi ...
    final card = PlayerInfoCard(
      player: player,
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
}

class _GameControlButtons extends StatelessWidget {
  // ... code widget này giữ nguyên không đổi ...
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
                    SoundService().playClickSound();
                    context.read<GameService>().markChatAsRead();
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
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
              onPressed: () {
                SoundService().playClickSound();
                onSurrenderPressed();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// *** WIDGET MỚI ĐƯỢC THÊM VÀO ***
class WinnerOverlay extends StatefulWidget {
  const WinnerOverlay({super.key});

  @override
  State<WinnerOverlay> createState() => _WinnerOverlayState();
}

class _WinnerOverlayState extends State<WinnerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Hiệu ứng nảy
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ), // Hiệu ứng mờ dần
    );

    // Bắt đầu chạy hiệu ứng
    _controller.forward();

    final gameService = context.read<GameService>();
    if (!gameService.isDraw) {
      // Chỉ phát âm thanh khi có người thắng, không phát khi hòa
      SoundService().playWinSound();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: AppColors.ink.withOpacity(0.7),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.highlight,
                    fontSize: 32,
                  ),
                ),
                // Có thể thêm các nút Chơi lại / Thoát ở đây nếu muốn
              ],
            ),
          ),
        ),
      ),
    );
  }
}
