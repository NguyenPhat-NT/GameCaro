import 'package:flutter/material.dart';
import '../models/player_model.dart';

class PlayerInfoCard extends StatelessWidget {
  final Player player;
  final bool isMyTurn;

  const PlayerInfoCard({
    super.key,
    required this.player,
    required this.isMyTurn,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyTurn ? player.color : Colors.transparent,
          width: 3,
        ),
        boxShadow: [
          if (isMyTurn)
            BoxShadow(
              color: player.color.withOpacity(0.5),
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
          // Quân cờ
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: player.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          // Tên người chơi
          Text(
            player.name,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
