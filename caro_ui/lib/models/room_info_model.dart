// lib/models/room_info_model.dart

class RoomInfo {
  final String roomId;
  final String hostName;
  final int playerCount;

  RoomInfo({
    required this.roomId,
    required this.hostName,
    required this.playerCount,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      roomId: json['RoomId'] as String,
      hostName: json['HostName'] as String,
      playerCount: json['PlayerCount'] as int,
    );
  }
}
