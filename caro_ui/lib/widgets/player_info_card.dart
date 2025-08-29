// caro_ui/lib/widgets/player_info_card.dart

import 'package:flutter/material.dart';
import '../game_theme.dart';
import '../models/player_model.dart';
import '../utils/symbol_painter_util.dart';

// THAY ĐỔI 1: Chuyển thành StatefulWidget
class PlayerInfoCard extends StatefulWidget {
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
  State<PlayerInfoCard> createState() => _PlayerInfoCardState();
}

// THAY ĐỔI 2: Thêm "with SingleTickerProviderStateMixin" để quản lý animation
class _PlayerInfoCardState extends State<PlayerInfoCard>
    with SingleTickerProviderStateMixin {
  // THAY ĐỔI 3: Khai báo AnimationController và Animation
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Tạo hiệu ứng scale từ 1.0 (kích thước gốc) -> 1.08 (lớn hơn 8%)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Bắt đầu hiệu ứng nếu đây là lượt của người chơi
    if (widget.isMyTurn) {
      _controller.repeat(reverse: true);
    }
  }

  // THAY ĐỔI 4: Thêm didUpdateWidget để bắt đầu/dừng hiệu ứng khi isMyTurn thay đổi
  @override
  void didUpdateWidget(covariant PlayerInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMyTurn != oldWidget.isMyTurn) {
      if (widget.isMyTurn) {
        _controller.repeat(reverse: true); // Bắt đầu lặp lại hiệu ứng
      } else {
        _controller.stop(); // Dừng hiệu ứng
        _controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 150),
        ); // Trở về kích thước gốc
      }
    }
  }

  @override
  void dispose() {
    // Hủy controller để tránh rò rỉ bộ nhớ
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // THAY ĐỔI 5: Dùng AnimatedBuilder và Transform.scale để áp dụng hiệu ứng
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Áp dụng hiệu ứng phóng to/thu nhỏ
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Opacity(
        opacity: widget.hasSurrendered ? 0.7 : 1.0,
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
                  // Đường viền vẫn đổi màu như cũ
                  color: widget.isMyTurn ? AppColors.highlight : AppColors.ink,
                  width: widget.isMyTurn ? 3.0 : 1.5,
                ),
                boxShadow: [
                  if (widget.isMyTurn)
                    BoxShadow(
                      color: AppColors.highlight.withOpacity(0.7),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: PlayerSymbol(
                playerId: widget.player.playerId,
                playerColor: widget.player.color,
                size: 36,
              ),
            ),
            if (widget.player.isHost)
              Positioned(
                top: -8,
                left: -8,
                child: Icon(Icons.star, color: AppColors.highlight, size: 20),
              ),
            if (widget.hasSurrendered)
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
      ),
    );
  }
}

// Các class PlayerSymbol và _SymbolPainter ở dưới giữ nguyên không thay đổi
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
