// caro_ui/lib/widgets/player_info_card.dart

import 'package:flutter/material.dart';
import '../game_theme.dart';
import '../models/player_model.dart';
import '../utils/symbol_painter_util.dart';

class PlayerInfoCard extends StatelessWidget {
  final Player player;
  final bool isMyTurn;
  final bool hasSurrendered;

  const PlayerInfoCard({
    super.key,
    required this.player,
    required this.isMyTurn,
    this.hasSurrendered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasSurrendered ? 0.7 : 1.0, // Giảm độ sáng một chút khi đầu hàng
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.parchment.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: isMyTurn ? AppColors.highlight : AppColors.ink,
                width: isMyTurn ? 3.0 : 1.5,
              ),
              boxShadow: [
                if (isMyTurn)
                  BoxShadow(
                    color: AppColors.highlight.withOpacity(0.7),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: PlayerSymbol(
              playerId: player.playerId,
              playerColor: player.color,
              size: 36,
            ),
          ),

          if (player.isHost)
            Positioned(
              top: -8,
              left: -8,
              child: Icon(Icons.star, color: AppColors.highlight, size: 20),
            ),

          // === THAY ĐỔI GIAO DIỆN ĐẦU HÀNG Ở ĐÂY ===
          if (hasSurrendered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Text(
                "OUT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlayerSymbol extends StatelessWidget {
  final int playerId;
  final Color playerColor;
  final double size;

  const PlayerSymbol({
    super.key,
    required this.playerId,
    required this.playerColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SymbolPainter(playerId: playerId, color: playerColor),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  final int playerId;
  final Color color;

  _SymbolPainter({required this.playerId, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    SymbolPainterUtil.drawSymbolForPlayer(
      canvas,
      playerId,
      center,
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
