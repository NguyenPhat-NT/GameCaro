import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../game_theme.dart';
import '../models/move_model.dart';
import '../widgets/board_painter.dart';

class GameBoard extends StatelessWidget {
  final int size;
  final List<Move> moves;
  final List<Player> players;
  final void Function(int x, int y) onMoveMade;

  const GameBoard({
    super.key,
    required this.size,
    required this.moves,
    required this.players,
    required this.onMoveMade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gridLines.withOpacity(0.5),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias, // Cắt các phần vẽ thừa ra ngoài bo tròn
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 0.5,
        maxScale: 2.0,
        child: GestureDetector(
          onTapUp: (details) {
            // Lấy kích thước của widget
            final RenderBox box = context.findRenderObject() as RenderBox;
            final double boardDimension = box.size.width;
            final double cellSize = boardDimension / size;

            // Tính toán tọa độ (x, y) dựa trên vị trí chạm
            final Offset localPosition = box.globalToLocal(
              details.globalPosition,
            );
            final int x = (localPosition.dx / cellSize).floor();
            final int y = (localPosition.dy / cellSize).floor();

            // Gọi callback để xử lý nước đi
            if (x >= 0 && x < size && y >= 0 && y < size) {
              onMoveMade(x, y);
            }
          },
          child: CustomPaint(
            size: const Size.square(double.infinity), // Lấp đầy không gian
            painter: BoardPainter(
              boardSize: size,
              moves: moves,
              players: players,
            ),
          ),
        ),
      ),
    );
  }
}
