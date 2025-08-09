// File: caro_ui/lib/models/chat_message_model.dart

class ChatMessage {
  final int playerId;
  final String playerName;
  final String message;

  ChatMessage({
    required this.playerId,
    required this.playerName,
    required this.message,
  });

  // Hàm này giúp chuyển đổi dữ liệu JSON từ server thành đối tượng ChatMessage
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      playerId: json['PlayerId'] as int,
      playerName: json['PlayerName'] as String? ?? 'Unknown',
      message: json['Message'] as String? ?? '',
    );
  }
}