// lib/widgets/game_board.dart

import 'package:flutter/material.dart';
import '../models/move_model.dart';
import '../models/player_model.dart';
import 'board_painter.dart';

class GameBoard extends StatefulWidget {
  final int width;
  final int height;
  final List<Move> moves;
  final List<Player> players;
  final void Function(int x, int y) onMoveMade;

  const GameBoard({
    super.key,
    required this.width,
    required this.height,
    required this.moves,
    required this.players,
    required this.onMoveMade,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    // Bạn có thể thêm logic setInitialZoom ở đây nếu muốn
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: EdgeInsets.zero,
      minScale: 0.5,
      maxScale: 4.0,
      child: GestureDetector(
        onTapUp: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final Offset localTapPosition = box.globalToLocal(
            details.globalPosition,
          );
          final Offset boardPosition = _transformationController.toScene(
            localTapPosition,
          );

          final double cellWidth = box.size.width / widget.width;
          final double cellHeight = box.size.height / widget.height;

          final int x = (boardPosition.dx / cellWidth).floor();
          final int y = (boardPosition.dy / cellHeight).floor();

          if (x >= 0 && x < widget.width && y >= 0 && y < widget.height) {
            widget.onMoveMade(x, y);
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: BoardPainter(
            boardWidth: widget.width,
            boardHeight: widget.height,
            moves: widget.moves,
            players: widget.players,
          ),
        ),
      ),
    );
  }
}
