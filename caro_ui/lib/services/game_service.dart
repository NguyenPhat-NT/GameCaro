import 'dart:async';
import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../models/player_model.dart';
import '../models/move_model.dart';

class GameService with ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  StreamSubscription? _messageSubscription;

  // State cho cả Lobby và Game
  String? _roomId;
  String? _sessionToken;
  int? _myPlayerId;
  List<Player> _players = [];
  List<Move> _moves = [];
  int? _currentPlayerId;
  bool _isGameStarted = false;
  int _boardSize = 20;

  // Getters để UI có thể truy cập
  String? get roomId => _roomId;
  List<Player> get players => _players;
  List<Move> get moves => _moves;
  int? get currentPlayerId => _currentPlayerId;
  bool get isGameStarted => _isGameStarted;
  int get boardSize => _boardSize;
  int? get myPlayerId => _myPlayerId;

  GameService() {
    // Lắng nghe tin nhắn từ NetworkService ngay khi được tạo
    _messageSubscription = _networkService.messages.listen(
      _handleServerMessage,
    );
  }

  void _handleServerMessage(Map<String, dynamic> message) {
    final type = message['Type'] as String;
    final payload = message['Payload'] as Map<String, dynamic>;

    switch (type) {
      case 'ROOM_CREATED':
        _roomId = payload['RoomId'];
        _sessionToken = payload['SessionToken'];
        print("Đã lưu SessionToken: $_sessionToken");
        break;

      case 'JOIN_RESULT':
        if (payload['Success'] == true) {
          _roomId = payload['RoomId'];
          _sessionToken = payload['SessionToken'];
          final playerList = payload['Players'] as List;
          _players = playerList.map((p) => Player.fromJson(p)).toList();
        }
        break;

      case 'PLAYER_JOINED':
        final newPlayer = Player.fromJson(payload);
        if (!_players.any((p) => p.playerId == newPlayer.playerId)) {
          _players.add(newPlayer);
        }
        break;

      case 'GAME_START':
        _isGameStarted = true;
        _currentPlayerId = payload['StartingPlayerId'];
        _boardSize = payload['BoardSize'] as int;
        final playerList = payload['Players'] as List;
        _players = playerList.map((p) => Player.fromJson(p)).toList();
        try {
          final myPlayerInfo = _players.firstWhere(
            (player) => player.sessionToken == _sessionToken,
          );
          _myPlayerId = myPlayerInfo.playerId;
          print("Xác định thành công! My Player ID is: $_myPlayerId");
        } catch (e) {
          print("Lỗi: Không tìm thấy người chơi có SessionToken khớp.");
        }

        break;

      case 'BOARD_UPDATE':
        final newMove = Move(
          x: payload['X'],
          y: payload['Y'],
          playerId: payload['PlayerId'],
        );
        _moves.add(newMove);
        break;

      case 'TURN_UPDATE':
        _currentPlayerId = payload['NextPlayerId'];
        break;

      case 'GAME_OVER':
        // Xử lý game over (hiển thị dialog,...)
        print("Game Over! Winner is ${payload['WinnerId']}");
        break;
    }

    // Thông báo cho tất cả các widget đang lắng nghe rằng đã có sự thay đổi
    notifyListeners();
  }

  // Các hàm để UI gọi
  void createRoom(String playerName) {
    _networkService.send('CREATE_ROOM', {'PlayerName': playerName});
  }

  void joinRoom(String roomId, String playerName) {
    // Gửi yêu cầu JOIN_ROOM theo tài liệu API [cite: 18]
    _networkService.send('JOIN_ROOM', {
      'PlayerName': playerName,
      'RoomId': roomId,
    });
  }

  void makeMove(int x, int y) {
    if (_currentPlayerId == _myPlayerId) {
      _networkService.send('MAKE_MOVE', {'X': x, 'Y': y});
    } else {
      print("Không thể đi. Chưa đến lượt của bạn!");
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
