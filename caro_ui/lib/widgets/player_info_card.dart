import 'package:flutter/material.dart';
import '../models/player_model.dart';

class PlayerInfoCard extends StatelessWidget {
  final Player player;
  final bool isMyTurn;

  // 1. Thêm danh sách màu vào trong widget, tương tự như BoardPainter
  final List<Color> playerColors = const [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];

  const PlayerInfoCard({
    super.key,
    required this.player,
    required this.isMyTurn,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy màu của người chơi hiện tại từ danh sách màu
    final currentPlayerColor =
        playerColors[player.playerId % playerColors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // 2. Sửa `player.color` thành `currentPlayerColor`
          color: isMyTurn ? currentPlayerColor : Colors.transparent,
          width: 3,
        ),
        boxShadow: [
          if (isMyTurn)
            BoxShadow(
              // 3. Sửa `player.color` thành `currentPlayerColor`
              color: currentPlayerColor.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // 4. Sửa `player.color` thành `currentPlayerColor`
              color: currentPlayerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            // 5. Sửa `player.name` thành `player.playerName`
            player.playerName,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
