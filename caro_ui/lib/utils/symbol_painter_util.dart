// lib/utils/symbol_painter_util.dart

import 'package:flutter/material.dart';
import 'dart:math';

class SymbolPainterUtil {
  static void drawSymbolForPlayer(
    Canvas canvas,
    int playerId,
    Offset center,
    double size,
    Paint paint,
  ) {
    final path = Path();
    switch (playerId % 4) {
      // Dùng % 4 để đảm bảo an toàn
      case 0: // X
        path.moveTo(center.dx - size, center.dy - size);
        path.lineTo(center.dx + size, center.dy + size);
        path.moveTo(center.dx + size, center.dy - size);
        path.lineTo(center.dx - size, center.dy + size);
        break;
      case 1: // Square
        path.addRect(
          Rect.fromCenter(
            center: center,
            width: size * 1.8,
            height: size * 1.8,
          ),
        );
        break;
      case 2: // Diamond
        path.moveTo(center.dx, center.dy - size);
        path.lineTo(center.dx + size * 0.8, center.dy);
        path.lineTo(center.dx, center.dy + size);
        path.lineTo(center.dx - size * 0.8, center.dy);
        path.close();
        break;
      case 3: // Star-like
        final double rLong = size;
        final double rShort = size * 0.5;
        for (int i = 0; i < 6; i++) {
          double angle = (pi / 3) * i - (pi / 2);
          double r = i.isEven ? rLong : rShort;
          var x = center.dx + cos(angle) * r;
          var y = center.dy + sin(angle) * r;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;
    }
    canvas.drawPath(path, paint);
  }
}
