import '../services/network_service.dart';
import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../game_theme.dart';
import '../models/move_model.dart';
import 'dart:convert';
import 'dart:async';

class GameService extends ChangeNotifier {
  final NetworkService _networkService = NetworkService();

  // Game State
  List<Player> _players = [];
  List<Move> _moves = [];
  int? _currentPlayerId;
  String? _roomId;
  bool _isConnected = false;
  String? _errorMessage;
  String? _myPlayerName;
  int? _myPlayerId;

  // Getters
  List<Player> get players => _players;
  List<Move> get moves => _moves;
  int? get currentPlayerId => _currentPlayerId;
  String? get roomId => _roomId;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;
  int? get myPlayerId => _myPlayerId;

  GameService() {
    _networkService.messages.listen(_onMessageReceived);
    // Gán hàm xử lý mất kết nối cho callback của NetworkService
    _networkService.onDisconnected = _handleDisconnection;
  }

  // Hàm được gọi khi NetworkService báo mất kết nối
  void _handleDisconnection(String reason) {
    if (!_isConnected) return; // Chỉ xử lý nếu trước đó đang kết nối

    print("Xử lý mất kết nối: $reason");
    _isConnected = false;
    _errorMessage = "Mất kết nối với server. Lý do: $reason";

    // Reset lại trạng thái game
    _players = [];
    _moves = [];
    _roomId = null;
    _currentPlayerId = null;
    _myPlayerId = null;
    _myPlayerName = null;

    notifyListeners();
  }

  Future<void> connectAndCreateRoom(String playerName) async {
    _myPlayerName = playerName;
    _errorMessage = null; // Xóa lỗi cũ
    final success = await _networkService.connect('103.157.205.146', 8888);
    if (success) {
      final createRoomMessage = {
        "Type": "CREATE_ROOM",
        "Payload": {"PlayerName": playerName},
      };
      _networkService.sendMessage(jsonEncode(createRoomMessage));
    } else {
      _errorMessage = "Không thể kết nối đến server.";
      notifyListeners();
    }
  }

  void makeMove(int x, int y) {
    // 1. Kiểm tra xem có phải lượt của mình không
    if (_currentPlayerId != _myPlayerId) {
      print("Không phải lượt của bạn!");
      // Có thể thêm logic để thông báo lỗi ra UI nếu cần
      // _errorMessage = "Không phải lượt của bạn!";
      // notifyListeners();
      return; // Dừng lại, không gửi nước đi
    }

    // 2. KIỂM TRA NƯỚC ĐI HỢP LỆ (LOGIC CỦA BẠN)
    // Kiểm tra xem tại tọa độ (x, y) đã có quân cờ nào chưa.
    final isMoveExist = _moves.any((move) => move.x == x && move.y == y);
    if (isMoveExist) {
      print("Vị trí ($x, $y) đã có người đi!");
      // Không cần gửi nước đi không hợp lệ lên server
      return;
    }

    // 3. Nếu mọi thứ hợp lệ, gửi nước đi lên server
    final makeMoveMessage = {
      "Type": "MAKE_MOVE",
      "Payload": {"X": x, "Y": y},
    };
    _networkService.sendMessage(jsonEncode(makeMoveMessage));
  }

  void _onMessageReceived(String jsonString) {
    try {
      final message = jsonDecode(jsonString);
      final type = message['Type'];
      final payload = message['Payload'];

      switch (type) {
        case 'ROOM_CREATED':
          _roomId = payload['RoomId'];
          _players = [
            Player(
              id: 0,
              name: _myPlayerName ?? "You",
              color: AppColors.player1,
            ),
          ];
          _myPlayerId = 0;
          _isConnected = true;
          _errorMessage = null;
          break;
        case 'PLAYER_JOINED':
          final colors = [
            AppColors.player1,
            AppColors.player2,
            AppColors.player3,
            AppColors.player4,
          ];
          _players.add(
            Player(
              id: payload['PlayerId'],
              name: payload['PlayerName'],
              color: colors[payload['PlayerId']],
            ),
          );
          break;
        case 'GAME_START':
          final List serverPlayers = payload['Players'];
          _players =
              serverPlayers.map((p) {
                final colors = [
                  AppColors.player1,
                  AppColors.player2,
                  AppColors.player3,
                  AppColors.player4,
                ];
                String name = p['Name'];
                if (p['Id'] == _myPlayerId) {
                  _myPlayerName = name;
                }
                return Player(id: p['Id'], name: name, color: colors[p['Id']]);
              }).toList();
          _currentPlayerId = payload['StartingPlayerId'];
          break;
        case 'GAME_STATE_UPDATE': // <--- THÊM CASE MỚI NÀY
          print("Đồng bộ lại toàn bộ trạng thái game...");
          final List serverPlayers = payload['Players'];
          final List serverMoves = payload['Moves'];

          // Cập nhật danh sách người chơi
          _players =
              serverPlayers.map((p) {
                final colors = [
                  AppColors.player1,
                  AppColors.player2,
                  AppColors.player3,
                  AppColors.player4,
                ];
                return Player(
                  id: p['Id'],
                  name: p['Name'],
                  color: colors[p['Id']],
                );
              }).toList();

          // Reset và cập nhật lại toàn bộ danh sách nước đi
          _moves =
              serverMoves.map((m) {
                return Move(x: m['X'], y: m['Y'], playerId: m['PlayerId']);
              }).toList();

          // Cập nhật lượt đi hiện tại
          _currentPlayerId = payload['CurrentPlayerId'];
          break;
        case 'BOARD_UPDATE':
          _moves.add(
            Move(
              x: payload['X'],
              y: payload['Y'],
              playerId: payload['PlayerId'],
            ),
          );
          break;
        case 'TURN_UPDATE':
          _currentPlayerId = payload['NextPlayerId'];
          break;
        case 'GAME_OVER':
          print("Game Over! Winner is ${payload['WinnerId']}");
          break;
      }
      notifyListeners();
    } catch (e) {
      print("Lỗi xử lý JSON: '$jsonString' - $e");
    }
  }

  @override
  void dispose() {
    _networkService.disconnect();
    super.dispose();
  }
}
