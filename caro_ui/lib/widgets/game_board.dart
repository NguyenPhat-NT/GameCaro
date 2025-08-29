// caro_ui/lib/widgets/game_board.dart

import 'dart:math';
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

class _GameBoardState extends State<GameBoard>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  Point<int>? _pendingCell;

  late AnimationController _moveController;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.elasticOut,
    );

    // THAY ĐỔI QUAN TRỌNG: Xóa bỏ listener ở đây
    // _moveAnimation.addListener(() {
    //   setState(() {});
    // });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox box = context.findRenderObject() as RenderBox;
      if (box.hasSize) {
        final boardWidth = box.size.width;
        final boardHeight = box.size.height;
        const double initialZoom = 2.2;
        final double translateX = (boardWidth - (boardWidth * initialZoom)) / 2;
        final double translateY =
            (boardHeight - (boardHeight * initialZoom)) / 2;
        final Matrix4 initialMatrix =
            Matrix4.identity()
              ..translate(translateX, translateY)
              ..scale(initialZoom);
        _transformationController.value = initialMatrix;
      }
    });
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    print(
      "DEBUG 5: [GameBoard] didUpdateWidget. Moves cũ: ${oldWidget.moves.length}, Moves mới: ${widget.moves.length}",
    );

    if (widget.moves.length > oldWidget.moves.length) {
      _moveController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _handleTap(Offset boardPosition, Size boardRenderSize) {
    // ... logic _handleTap giữ nguyên như cũ ...
    final double cellHorizontalSize = boardRenderSize.width / widget.width;
    final double cellVerticalSize = boardRenderSize.height / widget.height;
    final double cellSize = min(cellHorizontalSize, cellVerticalSize);

    final double gridRenderWidth = cellSize * widget.width;
    final double gridRenderHeight = cellSize * widget.height;
    final double offsetX = (boardRenderSize.width - gridRenderWidth) / 2;
    final double offsetY = (boardRenderSize.height - gridRenderHeight) / 2;

    final double relativeDx = boardPosition.dx - offsetX;
    final double relativeDy = boardPosition.dy - offsetY;

    final int x = (relativeDx / cellSize).floor();
    final int y = (relativeDy / cellSize).floor();

    if (x < 0 || x >= widget.width || y < 0 || y >= widget.height) {
      if (_pendingCell != null) {
        setState(() {
          _pendingCell = null;
        });
      }
      return;
    }

    if (_pendingCell != null && _pendingCell!.x == x && _pendingCell!.y == y) {
      widget.onMoveMade(x, y);
      setState(() {
        _pendingCell = null;
      });
    } else {
      setState(() {
        _pendingCell = Point(x, y);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardRenderSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return InteractiveViewer(
          transformationController: _transformationController,
          panAxis: PanAxis.vertical,
          minScale: 1.0,
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
              _handleTap(boardPosition, boardRenderSize);
            },
            child: CustomPaint(
              size: boardRenderSize,
              painter: BoardPainter(
                boardWidth: widget.width,
                boardHeight: widget.height,
                moves: widget.moves,
                players: widget.players,
                lastMove: widget.moves.isNotEmpty ? widget.moves.last : null,
                pendingCell: _pendingCell,
                moveAnimation:
                    _moveAnimation, // Giữ nguyên việc truyền animation
              ),
            ),
          ),
        );
      },
    );
  }
}
