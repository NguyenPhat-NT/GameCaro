// lib/widgets/board_painter.dart

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

  BoardPainter({
    required this.boardWidth,
    required this.boardHeight,
    required this.moves,
    required this.players,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellWidth = size.width / boardWidth;
    final double cellHeight = size.height / boardHeight;
    final gridPaint =
        Paint()
          ..color = AppColors.gridLines
          ..strokeWidth = 1.0;

    for (int i = 0; i <= boardWidth; i++) {
      final double xPos = i * cellWidth;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, size.height), gridPaint);
    }

    for (int i = 0; i <= boardHeight; i++) {
      final double yPos = i * cellHeight;
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), gridPaint);
    }

    for (final move in moves) {
      final player = players.firstWhere((p) => p.playerId == move.playerId);
      final piecePaint =
          Paint()
            ..color = player.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

      final double centerX = (move.x + 0.5) * cellWidth;
      final double centerY = (move.y + 0.5) * cellHeight;
      final double radius = min(cellWidth, cellHeight) * 0.4;

      canvas.drawCircle(Offset(centerX, centerY), radius, piecePaint);
      SymbolPainterUtil.drawSymbolForPlayer(
        canvas,
        move.playerId,
        Offset(centerX, centerY),
        radius * 0.7,
        piecePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.moves.length != moves.length;
  }
}
