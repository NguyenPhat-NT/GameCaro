import 'dart:math'; // Thêm import cho Point
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
  // THÊM MỚI: Biến state để lưu ô cờ đang được chọn tạm thời
  Point<int>? _pendingCell;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox box = context.findRenderObject() as RenderBox;
      if (box.hasSize) {
        final boardWidth = box.size.width;
        final boardHeight = box.size.height;
        const double initialZoom = 1.8;
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
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // THÊM MỚI: Hàm xử lý logic nhấn 2 lần
  void _handleTap(Offset boardPosition) {
    final double cellWidth =
        (context.findRenderObject() as RenderBox).size.width / widget.width;
    final double cellHeight =
        (context.findRenderObject() as RenderBox).size.height / widget.height;

    final int x = (boardPosition.dx / cellWidth).floor();
    final int y = (boardPosition.dy / cellHeight).floor();

    // Bỏ qua nếu nhấn ra ngoài bàn cờ
    if (x < 0 || x >= widget.width || y < 0 || y >= widget.height) {
      // Nếu đang có ô được chọn, hủy chọn nó
      if (_pendingCell != null) {
        setState(() {
          _pendingCell = null;
        });
      }
      return;
    }

    // Kiểm tra nếu nhấn lần thứ hai vào đúng ô đã chọn
    if (_pendingCell != null && _pendingCell!.x == x && _pendingCell!.y == y) {
      // Xác nhận nước đi
      widget.onMoveMade(x, y);
      setState(() {
        _pendingCell = null; // Xóa ô đang chờ
      });
    } else {
      // Lần nhấn đầu tiên hoặc nhấn vào một ô khác
      setState(() {
        _pendingCell = Point(x, y); // Đặt ô này làm ô đang chờ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.width / widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardRenderWidth = constraints.maxWidth;
          final boardRenderHeight = constraints.maxHeight;

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
                // Gọi hàm xử lý logic mới
                _handleTap(boardPosition);
              },
              child: CustomPaint(
                size: Size(boardRenderWidth, boardRenderHeight),
                painter: BoardPainter(
                  boardWidth: widget.width,
                  boardHeight: widget.height,
                  moves: widget.moves,
                  players: widget.players,
                  lastMove: widget.moves.isNotEmpty ? widget.moves.last : null,
                  // THÊM MỚI: Truyền ô đang chờ vào painter
                  pendingCell: _pendingCell,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
