// caro_ui/lib/models/player_model.dart

import 'package:flutter/material.dart';
import '../game_theme.dart';

class Player {
  final String playerName;
  final int playerId;
  final bool isHost; 
  final Color color;

  Player({
    required this.playerName,
    required this.playerId,
    required this.color,
    this.isHost = false,
  });

  // Factory constructor này lấy dữ liệu JSON từ server
  // và thêm vào đó thông tin màu sắc mà UI cần
  factory Player.fromJson(Map<String, dynamic> json) {
    int id = json['PlayerId'] as int;
    return Player(
      playerName: json['PlayerName'] as String,
      playerId: id,
      // Lấy IsHost từ JSON, nếu không có thì mặc định là false
      isHost: json['IsHost'] as bool? ?? false,
      // Tự động gán màu dựa trên playerId
      color: AppColors.playerColors[id % AppColors.playerColors.length],
    );
  }
}
