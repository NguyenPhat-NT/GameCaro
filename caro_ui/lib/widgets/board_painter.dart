import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../game_theme.dart';
import '../models/move_model.dart';

class BoardPainter extends CustomPainter {
  final int boardSize;
  final List<Move> moves;
  final List<Player> players;

  BoardPainter({
    required this.boardSize,
    required this.moves,
    required this.players,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double cellSize = width / boardSize;
    final List<Color> playerColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
    ];

    final gridPaint =
        Paint()
          ..color = AppColors.gridLines
          ..strokeWidth = 1.0;

    // Vẽ nền
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = AppColors.boardBackground,
    );

    // Vẽ các đường kẻ dọc và ngang
    for (int i = 0; i <= boardSize; i++) {
      final double pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, height), gridPaint); // Dọc
      canvas.drawLine(Offset(0, pos), Offset(width, pos), gridPaint); // Ngang
    }

    // Vẽ các quân cờ
    for (final move in moves) {
      // Xác định màu quân cờ dựa trên ID người chơi của nước đi
      final stonePaint =
          Paint()..color = playerColors[move.playerId % playerColors.length];

      final double centerX = (move.x + 0.5) * cellSize;
      final double centerY = (move.y + 0.5) * cellSize;
      final double radius = cellSize * 0.4; // Bán kính quân cờ

      // Vẽ bóng cho quân cờ để tạo chiều sâu
      canvas.drawCircle(
        Offset(centerX + 1, centerY + 1),
        radius,
        Paint()..color = Colors.black.withOpacity(0.3),
      );
      // Vẽ quân cờ
      canvas.drawCircle(Offset(centerX, centerY), radius, stonePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    // Chỉ vẽ lại khi danh sách nước đi thay đổi
    return oldDelegate.moves.length != moves.length;
  }
}
