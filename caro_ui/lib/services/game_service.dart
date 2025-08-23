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
  bool _hasUnreadMessages = false; // Biến cờ hiệu
  bool _shouldReturnToLobby = false;
  bool _isFirstLobbyLoad = true;
  final Set<int> _surrenderedPlayerIds =
      {}; // <<< THÊM MỚI: Theo dõi người chơi đã đầu hàng
  List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;
  List<RoomInfo> _availableRooms = [];
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
  final Set<int> _disconnectedPlayerIds = {};
  Set<int> get disconnectedPlayerIds => _disconnectedPlayerIds;

  bool get shouldNavigateHome => _shouldNavigateHome;
  Set<int> get surrenderedPlayerIds => _surrenderedPlayerIds; // <<< THÊM MỚI
  List<RoomInfo> get availableRooms => _availableRooms;

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
    _chatMessages.clear();
    _surrenderedPlayerIds.clear(); // <-- THÊM DÒNG NÀY
    // Không gọi notifyListeners() ở đây để tránh lỗi khi đang build UI
  }

  void consumeReturnToLobbySignal() {
    _shouldReturnToLobby = false;
  }

  bool consumeFirstLobbyLoad() {
    if (_isFirstLobbyLoad) {
      _isFirstLobbyLoad = false;
      return true; // Đúng, đây là lần đầu tiên
    }
    return false; // Không, đây là các lần sau
  }

  void _handleServerMessage(Map<String, dynamic> message) {
    final type = message['Type'] as String;
    final payload = message['Payload'] as Map<String, dynamic>? ?? {};

    // --- LOG DEBUG ---
    print("----------------------------------------------------");
    print("DEBUG: Received message type: $type");
    print("DEBUG: RoomID BEFORE processing: $_roomId");
    // --- KẾT THÚC LOG DEBUG ---

    switch (type) {
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
        print("Trận đấu bắt đầu! My Player ID is: $_myPlayerId");
        break;

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
          print(
            "✅ Returned to lobby. Updated player list: ${_players.length} players.",
          );
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
        // --- LOG DEBUG ---
        print(
          "DEBUG: Clearing RoomID because of LEAVE_ROOM_SUCCESS or ROOM_CLOSED.",
        );
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
          final myPlayerInRoom = _players.firstWhere(
            (p) => p.playerName == _myPlayerName,
            orElse: () => _players.last,
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

      case 'GAME_STATE_UPDATE':
        if (payload.containsKey('ChatHistory')) {
          final chatHistoryList = payload['ChatHistory'] as List;
          _chatMessages =
              chatHistoryList
                  .map(
                    (chat) =>
                        ChatMessage.fromJson(chat as Map<String, dynamic>),
                  )
                  .toList();
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

      case 'RECONNECT_RESULT':
        final success = payload['Success'] as bool? ?? false;
        if (success) {
          print("✅ Reconnect success! Restoring game state...");
          final gameState = payload['GameState'] as Map<String, dynamic>;
          final playerList = gameState['Players'] as List;
          _players =
              playerList
                  .map((p) => Player.fromJson(p as Map<String, dynamic>))
                  .toList();
          final myPlayerInfo = _players.firstWhere(
            (p) => p.playerName == _myPlayerName,
          );
          _myPlayerId = myPlayerInfo.playerId;
          final movesList = gameState['Moves'] as List;
          _moves =
              movesList
                  .map(
                    (m) => Move(x: m['X'], y: m['Y'], playerId: m['PlayerId']),
                  )
                  .toList();
          _currentPlayerId = gameState['CurrentPlayerId'];
          final chatHistoryList = gameState['ChatHistory'] as List;
          _chatMessages =
              chatHistoryList
                  .map(
                    (chat) =>
                        ChatMessage.fromJson(chat as Map<String, dynamic>),
                  )
                  .toList();
          _isGameStarted = true;
        } else {
          print(
            "🚨 Reconnect failed! (Game may have ended). Deleting session.",
          );
          _dbService.deleteSession();
        }
        break;
    }

    // --- LOG DEBUG ---
    print("DEBUG: RoomID AFTER processing: $_roomId");
    print("----------------------------------------------------");
    // --- KẾT THÚC LOG DEBUG ---
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
      notifyListeners(); // Thông báo cho UI cập nhật (để xóa chấm đỏ)
    }
  }

  void findMatch(String playerName) {
    // 1. Lưu lại tên người chơi
    setMyPlayerName(playerName);
    // 2. Gửi yêu cầu FIND_MATCH lên server
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
    // Cập nhật lại tên người chơi từ session đã lưu, phòng trường hợp state bị mất
    _myPlayerName = playerName;
    _roomId = roomId;
    // Gửi yêu cầu RECONNECT lên server
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
