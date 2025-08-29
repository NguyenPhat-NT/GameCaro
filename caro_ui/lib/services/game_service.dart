// caro_ui/lib/services/game_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'network_service.dart';
import '../models/player_model.dart';
import '../models/chat_message_model.dart';
import '../models/move_model.dart';
import '../models/room_info_model.dart';
import '../game_theme.dart';
import 'sound_service.dart';

class GameService with ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  final DatabaseService _dbService = DatabaseService();
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
  bool _hasUnreadMessages = false;
  bool _shouldReturnToLobby = false;
  bool _isFirstLobbyLoad = true;
  final Set<int> _surrenderedPlayerIds = {};
  List<ChatMessage> _chatMessages = [];
  List<RoomInfo> _availableRooms = [];
  final Set<int> _disconnectedPlayerIds = {};

  // Getters
  String? get roomId => _roomId;
  List<Player> get players => _players;
  List<Move> get moves => _moves;
  int? get currentPlayerId => _currentPlayerId;
  bool get isGameStarted => _isGameStarted;
  int get boardSize => _boardSize;
  int? get myPlayerId => _myPlayerId;
  String? get myPlayerName => _myPlayerName;
  int? get winnerId => _winnerId;
  bool get isDraw => _isDraw;
  bool get shouldReturnToLobby => _shouldReturnToLobby;
  bool get hasUnreadMessages => _hasUnreadMessages;
  Set<int> get disconnectedPlayerIds => _disconnectedPlayerIds;
  bool get shouldNavigateHome => _shouldNavigateHome;
  Set<int> get surrenderedPlayerIds => _surrenderedPlayerIds;
  List<RoomInfo> get availableRooms => _availableRooms;
  List<ChatMessage> get chatMessages => _chatMessages;

  GameService() {
    _messageSubscription = _networkService.messages.listen(
      _handleServerMessage,
    );
  }

  void _handleServerMessage(Map<String, dynamic> message) {
    final type = message['Type'] as String;
    final payload = message['Payload'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'BOARD_UPDATE':
        final movePlayerId = payload['PlayerId'] as int;

        if (movePlayerId == _myPlayerId) {
          break;
        }

        final newMove = Move(
          x: payload['X'],
          y: payload['Y'],
          playerId: movePlayerId,
        );

        if (!_moves.any((m) => m.x == newMove.x && m.y == newMove.y)) {
          // *** THAY ĐỔI QUAN TRỌNG SỐ 1 ***
          // Tạo một danh sách mới thay vì chỉ .add()
          _moves = List.from(_moves)..add(newMove);
        }
        break;

      // ... Các case khác giữ nguyên ...
      case 'GAME_START':
        _isGameStarted = true;
        _moves.clear();
        _winnerId = null;
        _isDraw = false;
        _surrenderedPlayerIds.clear();
        _disconnectedPlayerIds.clear();
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
        break;

      case 'TURN_UPDATE':
        _currentPlayerId = payload['NextPlayerId'];
        break;

      // ... dán tất cả các case khác của bạn vào đây ...
      case 'ROOM_LIST_UPDATE':
        final roomsList = payload['Rooms'] as List;
        _availableRooms =
            roomsList.map((roomJson) {
              return RoomInfo.fromJson(roomJson as Map<String, dynamic>);
            }).toList();
        break;

      case 'PLAYER_SURRENDERED':
        final playerId = payload['PlayerId'] as int?;
        if (playerId != null) {
          _surrenderedPlayerIds.add(playerId);
        }
        break;

      case 'RETURN_TO_LOBBY':
        _isGameStarted = false;
        _moves.clear();
        _winnerId = null;
        _isDraw = false;
        _currentPlayerId = null;
        _surrenderedPlayerIds.clear();
        _disconnectedPlayerIds.clear();
        if (payload.containsKey('Players')) {
          final playerList = payload['Players'] as List;
          _players =
              playerList
                  .map((p) => Player.fromJson(p as Map<String, dynamic>))
                  .toList();
        }
        _shouldReturnToLobby = true;
        break;

      case 'PLAYER_LEFT':
        final playerId = payload['PlayerId'] as int;
        _players.removeWhere((p) => p.playerId == playerId);
        _disconnectedPlayerIds.remove(playerId);
        break;

      case 'LEAVE_ROOM_SUCCESS':
      case 'ROOM_CLOSED':
        _roomId = null;
        _players = [];
        _isGameStarted = false;
        _moves = [];
        _chatMessages = [];
        _dbService.deleteSession();
        break;

      case 'ROOM_CREATED':
        _roomId = payload['RoomId'];
        _sessionToken = payload['SessionToken'];
        _myPlayerId = 0;
        _chatMessages.clear();
        _players = [
          Player(
            playerId: 0,
            playerName: _myPlayerName ?? "Bạn",
            color: AppColors.playerColors[0],
            isHost: true,
          ),
        ];
        _dbService.saveSession(
          roomId: _roomId!,
          sessionToken: _sessionToken!,
          myPlayerId: _myPlayerId!,
          myPlayerName: _myPlayerName!,
        );
        break;

      case 'JOIN_RESULT':
        if (payload['Success'] == true) {
          _roomId = payload['RoomId'];
          _sessionToken = payload['SessionToken'];
          final playerList = payload['Players'] as List;
          _chatMessages.clear();
          _players =
              playerList
                  .map((p) => Player.fromJson(p as Map<String, dynamic>))
                  .toList();
          if (!_players.any((p) => p.playerName == _myPlayerName)) {
            final myId = _players.length; // Sẽ là 0 nếu ta là người đầu tiên
            final amIHost = _players.isEmpty;

            // Tự thêm thông tin của mình vào danh sách
            _players.add(
              Player(
                playerName: _myPlayerName!,
                playerId: myId,
                color:
                    AppColors.playerColors[myId %
                        AppColors.playerColors.length],
                isHost: amIHost,
              ),
            );
          }

          // Bây giờ, danh sách _players sẽ không bao giờ rỗng khi ta tìm kiếm
          final myPlayerInRoom = _players.firstWhere(
            (p) => p.playerName == _myPlayerName,
          );
          _myPlayerId = myPlayerInRoom.playerId;

          _dbService.saveSession(
            roomId: _roomId!,
            sessionToken: _sessionToken!,
            myPlayerId: _myPlayerId!,
            myPlayerName: _myPlayerName!,
          );
        }
        break;

      case 'PLAYER_JOINED':
        final newPlayer = Player.fromJson(payload);
        if (!_players.any((p) => p.playerId == newPlayer.playerId)) {
          _players.add(newPlayer);
        }
        break;

      case 'CHAT_MESSAGE_RECEIVED':
        final newChatMessage = ChatMessage.fromJson(payload);
        _chatMessages.add(newChatMessage);
        final chatPayload = payload as Map<String, dynamic>;
        final senderId = chatPayload['PlayerId'] as int?;
        if (senderId != null && senderId != _myPlayerId) {
          _hasUnreadMessages = true;
        }
        break;

      case 'GAME_OVER':
        _isDraw = payload['IsDraw'] as bool? ?? false;
        if (!_isDraw) {
          _winnerId = payload['WinnerId'] as int?;
        }
        break;

      case 'PLAYER_DISCONNECTED':
        final playerId = payload['PlayerId'] as int?;
        if (playerId != null) {
          _disconnectedPlayerIds.add(playerId);
        }
        break;

      case 'PLAYER_RECONNECTED':
        final playerId = payload['PlayerId'] as int?;
        if (playerId != null) {
          _disconnectedPlayerIds.remove(playerId);
        }
        break;
    }
    notifyListeners();
  }

  void makeMove(int x, int y) {
    if (_currentPlayerId == _myPlayerId && _isGameStarted) {
      if (_moves.any((move) => move.x == x && move.y == y)) {
        return;
      }

      SoundService().playMoveSound();

      final tentativeMove = Move(x: x, y: y, playerId: _myPlayerId!);

      // *** THAY ĐỔI QUAN TRỌNG SỐ 2 ***
      // Tạo một danh sách mới thay vì chỉ .add()
      _moves = List.from(_moves)..add(tentativeMove);

      _currentPlayerId = -1;
      notifyListeners();

      _networkService.send('MAKE_MOVE', {'X': x, 'Y': y});
    }
  }

  // ... dán tất cả các hàm còn lại của bạn (resetState, joinRoom, etc.) vào đây ...

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
    _chatMessages.clear();
  }

  void consumeReturnToLobbySignal() {
    _shouldReturnToLobby = false;
  }

  bool consumeFirstLobbyLoad() {
    if (_isFirstLobbyLoad) {
      _isFirstLobbyLoad = false;
      return true;
    }
    return false;
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

  void getRoomList() {
    _networkService.send('GET_ROOM_LIST', {});
  }

  void setMyPlayerName(String name) {
    _myPlayerName = name;
  }

  void surrender() {
    if (_isGameStarted) {
      _networkService.send('SURRENDER', {});
    }
  }

  void markChatAsRead() {
    if (_hasUnreadMessages) {
      _hasUnreadMessages = false;
      notifyListeners();
    }
  }

  void findMatch(String playerName) {
    setMyPlayerName(playerName);
    _networkService.send('FIND_MATCH', {'PlayerName': playerName});
  }

  void leaveRoom() {
    if (_roomId != null) {
      _networkService.send('LEAVE_ROOM', {});
    }
  }

  void sendChatMessage(String message) {
    if (message.trim().isNotEmpty) {
      _networkService.send('SEND_CHAT_MESSAGE', {'Message': message});
    }
  }

  void startGameEarly() {
    if (_players.any((p) => p.playerId == _myPlayerId && p.isHost)) {
      _networkService.send('START_GAME_EARLY', {});
    }
  }

  void reconnectToGame(String roomId, String sessionToken, String playerName) {
    _myPlayerName = playerName;
    _roomId = roomId;
    _networkService.send('RECONNECT', {
      'RoomId': roomId,
      'SessionToken': sessionToken,
    });
    print("🚀 Sending reconnect request for room: $roomId");
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
