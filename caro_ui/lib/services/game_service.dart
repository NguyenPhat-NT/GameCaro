// caro_ui/lib/services/game_service.dart

import 'dart:async';
import 'package:flutter/material.dart';

import 'network_service.dart';
import '../models/player_model.dart';
import '../models/move_model.dart';
import '../game_theme.dart';

class GameService with ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  StreamSubscription? _messageSubscription;

  // State
  String? _roomId;
  String? _sessionToken;
  int? _myPlayerId;
  String? _myPlayerName;
  List<Player> _players = [];
  List<Move> _moves = [];
  int? _currentPlayerId;
  bool _isGameStarted = false;
  int _boardSize = 25;
  int? _winnerId;
  bool _isDraw = false;
  bool _shouldNavigateHome = false;
  final Set<int> _surrenderedPlayerIds =
      {}; // <<< THÊM MỚI: Theo dõi người chơi đã đầu hàng

  // Getters
  String? get roomId => _roomId;
  List<Player> get players => _players;
  List<Move> get moves => _moves;
  int? get currentPlayerId => _currentPlayerId;
  bool get isGameStarted => _isGameStarted;
  int get boardSize => _boardSize;
  int? get myPlayerId => _myPlayerId;
  int? get winnerId => _winnerId;
  bool get isDraw => _isDraw;
  bool get shouldNavigateHome => _shouldNavigateHome;
  Set<int> get surrenderedPlayerIds => _surrenderedPlayerIds; // <<< THÊM MỚI

  GameService() {
    _messageSubscription = _networkService.messages.listen(
      _handleServerMessage,
    );
  }

  void resetStateForNewConnection() {
    _roomId = null;
    _sessionToken = null;
    _myPlayerId = null;
    _myPlayerName = null;
    _players = [];
    _moves = [];
    _currentPlayerId = null;
    _isGameStarted = false;
    _winnerId = null;
    _isDraw = false;
    _shouldNavigateHome = false;
    _surrenderedPlayerIds.clear();
  }

  void _handleServerMessage(Map<String, dynamic> message) {
    final type = message['Type'] as String;
    final payload = message['Payload'] as Map<String, dynamic>? ?? {};

    switch (type) {
      // ... các case khác giữ nguyên

      case 'GAME_START':
        _isGameStarted = true;
        _moves.clear();
        _winnerId = null;
        _isDraw = false;
        _surrenderedPlayerIds
            .clear(); // <<< THÊM MỚI: Reset khi game mới bắt đầu
        _currentPlayerId = payload['StartingPlayerId'];
        _boardSize = payload['BoardSize'] as int;
        final playerList = payload['Players'] as List;
        _players =
            playerList
                .map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList();
        final myPlayerInGame = _players.firstWhere(
          (p) => p.playerName == _myPlayerName,
          orElse: () => _players.first,
        );
        _myPlayerId = myPlayerInGame.playerId;
        print("Trận đấu bắt đầu! My Player ID is: $_myPlayerId");
        break;

      // <<< THÊM MỚI: Xử lý khi có người chơi đầu hàng
      case 'PLAYER_SURRENDERED':
        final playerId = payload['PlayerId'] as int?;
        if (playerId != null) {
          _surrenderedPlayerIds.add(playerId);
        }
        break;

      // ... các case khác giữ nguyên
      case 'ROOM_CREATED':
        _roomId = payload['RoomId'];
        _sessionToken = payload['SessionToken'];
        _myPlayerId = 0;
        _players = [
          Player(
            playerId: 0,
            playerName: _myPlayerName ?? "Bạn",
            color: AppColors.playerColors[0],
            isHost: true,
          ),
        ];
        break;
      case 'JOIN_RESULT':
        if (payload['Success'] == true) {
          _roomId = payload['RoomId'];
          _sessionToken = payload['SessionToken'];
          final playerList = payload['Players'] as List;
          _players =
              playerList
                  .map((p) => Player.fromJson(p as Map<String, dynamic>))
                  .toList();
          if (!_players.any((p) => p.playerName == _myPlayerName)) {
            final myId = _players.length;
            _myPlayerId = myId;
            _players.add(
              Player(
                playerName: _myPlayerName!,
                playerId: myId,
                color: AppColors.playerColors[myId % 4],
                isHost: false,
              ),
            );
          }
        }
        break;
      case 'PLAYER_JOINED':
        final newPlayer = Player.fromJson(payload);
        if (!_players.any((p) => p.playerId == newPlayer.playerId)) {
          _players.add(newPlayer);
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
        _isDraw = payload['IsDraw'] as bool? ?? false;
        if (!_isDraw) {
          _winnerId = payload['WinnerId'] as int?;
        }
        print("Game Over! WinnerId: $_winnerId, IsDraw: $_isDraw");
        break;
      case 'LEAVE_ROOM_SUCCESS':
      case 'ROOM_CLOSED':
        _shouldNavigateHome = true;
        break;
    }
    notifyListeners();
  }

  void createRoom(String playerName) {
    _myPlayerName = playerName;
    _networkService.send('CREATE_ROOM', {'PlayerName': playerName});
  }

  void joinRoom(String roomId, String playerName) {
    _myPlayerName = playerName;
    _networkService.send('JOIN_ROOM', {
      'PlayerName': playerName,
      'RoomId': roomId,
    });
  }

  void makeMove(int x, int y) {
    if (_currentPlayerId == _myPlayerId && _isGameStarted) {
      _networkService.send('MAKE_MOVE', {'X': x, 'Y': y});
    }
  }

  void surrender() {
    if (_isGameStarted) {
      _networkService.send('SURRENDER', {});
    }
  }

  void leaveRoom() {
    if (_roomId != null) {
      _networkService.send('LEAVE_ROOM', {});
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
