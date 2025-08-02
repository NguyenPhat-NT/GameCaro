import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../game_theme.dart';
import '../widgets/player_info_card.dart';
import '../widgets/game_board.dart';
import '../services/game_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_service.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy GameService từ Provider
    final gameService = context.watch<GameService>();

    // Xử lý khi không có người chơi (trạng thái khởi tạo)
    if (gameService.players.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Đang chờ người chơi khác...")),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopInfoBar(context, gameService),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    _buildPlayersColumn(context, gameService, [0, 1]),
                    Expanded(
                      child: GameBoard(
                        size: gameService.boardSize, // Lấy từ service
                        moves: gameService.moves,
                        players: gameService.players,
                        onMoveMade: (x, y) {
                          // Chỉ cho phép đi khi đến lượt
                          // Cần có ID của client để so sánh chính xác
                          if (gameService.currentPlayerId !=
                              null /*&& gameService.currentPlayerId == myId*/ ) {
                            gameService.makeMove(x, y);
                          } else {
                            print("Chưa đến lượt của bạn!");
                          }
                        },
                      ),
                    ),
                    _buildPlayersColumn(context, gameService, [2, 3]),
                  ],
                ),
              ),
            ),
            _buildControlButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoBar(BuildContext context, GameService gameService) {
    final currentPlayer = gameService.players.firstWhere(
      (p) => p.playerId == gameService.currentPlayerId,
      orElse: () => Player(playerId: -1, playerName: "..."),
    );

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Phòng: ${gameService.roomId ?? '...'}",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            "Lượt của: ${currentPlayer.playerName}",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildPlayersColumn(
    BuildContext context,
    GameService gameService,
    List<int> playerIndexes,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: playerIndexes.map((index) {
        if (index < gameService.players.length) {
          final player = gameService.players[index];
          return PlayerInfoCard(
            player: player,
            isMyTurn: player.playerId == gameService.currentPlayerId,
          );
        }
        return const SizedBox(width: 100, height: 100); // Placeholder
      }).toList(),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text("Chat", style: Theme.of(context).textTheme.labelLarge),
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(
              "Game Mới",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.player3),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.flag_outlined),
            label: Text(
              "Đầu Hàng",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.player1),
          ),
        ],
      ),
    );
  }
}
