import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../game_theme.dart';
import '../widgets/player_info_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Dữ liệu giả lập - sau này sẽ thay bằng dữ liệu từ server
  late final List<Player> players;
  int currentPlayerId = 0; // ID của người chơi hiện tại

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách người chơi giả lập
    players = [
      Player(id: 0, name: "Player 1", color: AppColors.player1),
      Player(id: 1, name: "Player 2", color: AppColors.player2),
      Player(id: 2, name: "Player 3", color: AppColors.player3),
      Player(id: 3, name: "Player 4", color: AppColors.player4),
    ];
  }

  // Hàm để chuyển lượt (dùng để test)
  void _nextTurn() {
    setState(() {
      currentPlayerId = (currentPlayerId + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // VÙNG THÔNG TIN TRẬN ĐẤU (TASK 1.10)
            _buildTopInfoBar(),

            // VÙNG CHÍNH CỦA GAME
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    // Cột thông tin người chơi bên trái
                    _buildPlayersColumn([players[0], players[1]]),

                    // VÙNG BÀN CỜ (TASK 1.11)
                    Expanded(child: _buildGameBoard()),

                    // Cột thông tin người chơi bên phải
                    _buildPlayersColumn([players[2], players[3]]),
                  ],
                ),
              ),
            ),

            // VÙNG CÁC NÚT ĐIỀU KHIỂN (TASK 1.9)
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  // Widget cho thanh thông tin trên cùng
  Widget _buildTopInfoBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Phòng: XYZ123", style: Theme.of(context).textTheme.bodyMedium),
          Text(
            "Lượt của: ${players[currentPlayerId].name}",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: players[currentPlayerId].color,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              /* TODO: Mở menu */
            },
          ),
        ],
      ),
    );
  }

  // Widget cho cột thông tin người chơi
  Widget _buildPlayersColumn(List<Player> playerList) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          playerList
              .map(
                (player) => PlayerInfoCard(
                  player: player,
                  isMyTurn: player.id == currentPlayerId,
                ),
              )
              .toList(),
    );
  }

  // Widget placeholder cho bàn cờ
  Widget _buildGameBoard() {
    return GestureDetector(
      onTap: _nextTurn, // Chạm vào bàn cờ để test chuyển lượt
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: AppColors.boardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gridLines, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "BÀN CỜ 20x20\n(Scroll & Zoom)",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Widget cho các nút điều khiển dưới cùng
  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text("Chat", style: Theme.of(context).textTheme.labelLarge),
            onPressed: () {
              /* TODO: Mở khung chat */
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(
              "Game Mới",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onPressed: () {
              /* TODO: Gửi yêu cầu game mới */
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.player3),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.flag_outlined),
            label: Text(
              "Đầu Hàng",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onPressed: () {
              /* TODO: Gửi yêu cầu đầu hàng */
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.player1),
          ),
        ],
      ),
    );
  }
}
