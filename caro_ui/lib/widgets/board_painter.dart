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
  final Point<int>? pendingCell;

  BoardPainter({
    required this.boardWidth,
    required this.boardHeight,
    required this.moves,
    required this.players,
    this.lastMove,
    this.pendingCell,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellHorizontalSize = size.width / boardWidth;
    final double cellVerticalSize = size.height / boardHeight;
    final double cellSize = min(cellHorizontalSize, cellVerticalSize);

    final double gridRenderWidth = cellSize * boardWidth;
    final double gridRenderHeight = cellSize * boardHeight;
    final double offsetX = (size.width - gridRenderWidth) / 2;
    final double offsetY = (size.height - gridRenderHeight) / 2;

    final gridPaint =
        Paint()
          ..color = AppColors.gridLines
          ..strokeWidth = 1.0;

    // Vẽ lưới cờ
    for (int i = 0; i <= boardWidth; i++) {
      final double xPos = offsetX + i * cellSize;
      canvas.drawLine(
        Offset(xPos, offsetY),
        Offset(xPos, offsetY + gridRenderHeight),
        gridPaint,
      );
    }
    for (int i = 0; i <= boardHeight; i++) {
      final double yPos = offsetY + i * cellSize;
      canvas.drawLine(
        Offset(offsetX, yPos),
        Offset(offsetX + gridRenderWidth, yPos),
        gridPaint,
      );
    }

    // Vẽ các nước đi
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

      final double centerX = offsetX + (move.x + 0.5) * cellSize;
      final double centerY = offsetY + (move.y + 0.5) * cellSize;
      final double radius = cellSize * 0.4;

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

    if (pendingCell != null) {
      final Rect cellRect = Rect.fromLTWH(
        offsetX + pendingCell!.x * cellSize,
        offsetY + pendingCell!.y * cellSize,
        cellSize,
        cellSize,
      );
      final pendingPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.25)
            ..style = PaintingStyle.fill;
      canvas.drawRect(cellRect, pendingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.moves.length != moves.length ||
        oldDelegate.lastMove != lastMove ||
        oldDelegate.pendingCell != oldDelegate.pendingCell;
  }
}
