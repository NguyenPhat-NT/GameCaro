import 'package:flutter/material.dart';
import 'dart:math';
import '../game_theme.dart';
import '../models/move_model.dart';
import '../models/player_model.dart';
import '../utils/symbol_painter_util.dart';

class BoardPainter extends CustomPainter {
  final int boardWidth;
  final int boardHeight;
  final List<Move> moves;
  final List<Player> players;
  final Move? lastMove;
  // THÊM MỚI: Thuộc tính để nhận ô đang chờ
  final Point<int>? pendingCell;

  BoardPainter({
    required this.boardWidth,
    required this.boardHeight,
    required this.moves,
    required this.players,
    this.lastMove,
    this.pendingCell, // Thêm vào constructor
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / boardWidth;
    final double cellHeight = size.height / boardHeight;
    final gridPaint =
        Paint()
          ..color = AppColors.gridLines
          ..strokeWidth = 1.0;

    // Vẽ lưới
    for (int i = 0; i <= boardWidth; i++) {
      final double xPos = i * cellWidth;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, size.height), gridPaint);
    }
    for (int i = 0; i <= boardHeight; i++) {
      final double yPos = i * cellHeight;
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), gridPaint);
    }

    // Vẽ các nước đi đã thực hiện
    for (final move in moves) {
      Player player;
      try {
        player = players.firstWhere((p) => p.playerId == move.playerId);
      } catch (e) {
        player = Player(
          playerId: -1,
          playerName: 'Unknown',
          color: Colors.grey,
        );
      }

      final piecePaint =
          Paint()
            ..color = player.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

      final double centerX = (move.x + 0.5) * cellWidth;
      final double centerY = (move.y + 0.5) * cellHeight;
      final double radius = min(cellWidth, cellHeight) * 0.4;

      if (lastMove != null && move.x == lastMove!.x && move.y == lastMove!.y) {
        final glowPaint =
            Paint()
              ..color = player.color.withOpacity(0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.0
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(Offset(centerX, centerY), radius + 2.0, glowPaint);
      }

      canvas.drawCircle(Offset(centerX, centerY), radius, piecePaint);
      SymbolPainterUtil.drawSymbolForPlayer(
        canvas,
        move.playerId,
        Offset(centerX, centerY),
        radius * 0.7,
        piecePaint,
      );
    }

    // THÊM MỚI: Vẽ dấu hiệu cho ô đang chờ
    if (pendingCell != null) {
      final double centerX = (pendingCell!.x + 0.5) * cellWidth;
      final double centerY = (pendingCell!.y + 0.5) * cellHeight;

      final pendingPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.25) // Một lớp phủ mờ màu tối
            ..style = PaintingStyle.fill;

      final Rect cellRect = Rect.fromLTWH(
        pendingCell!.x * cellWidth,
        pendingCell!.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(cellRect, pendingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    // Thêm pendingCell vào điều kiện vẽ lại
    return oldDelegate.moves.length != moves.length ||
        oldDelegate.lastMove != lastMove ||
        oldDelegate.pendingCell != pendingCell;
  }
}
