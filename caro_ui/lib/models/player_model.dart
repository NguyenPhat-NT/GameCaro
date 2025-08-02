// lib/models/player_model.dart

import 'dart:ui';

class Player {
  final String playerName;
  final int playerId;
  final String? sessionToken;

  Player({required this.playerName, required this.playerId, this.sessionToken});

  // Một factory constructor để dễ dàng tạo Player từ JSON (Map)
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      playerName: json['PlayerName'] as String,
      playerId: json['PlayerId'] as int,
      sessionToken: json['SessionToken'] as String?,
    );
  }
}
