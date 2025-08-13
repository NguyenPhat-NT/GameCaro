// lib/screens/room_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../game_theme.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  @override
  void initState() {
    super.initState();
    // Yêu cầu danh sách phòng ngay khi màn hình được tải
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameService>().getRoomList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<GameService>();
    final rooms = gameService.availableRooms;
    final myPlayerName = gameService.myPlayerName;

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.woodFrame,
        title: const Text(
          'Danh sách phòng',
          style: TextStyle(color: AppColors.parchment),
        ),
        iconTheme: const IconThemeData(color: AppColors.parchment),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => gameService.getRoomList(),
          ),
        ],
      ),
      body:
          rooms.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tìm phòng...'),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return Card(
                    color: AppColors.parchment.withOpacity(0.8),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.woodFrame,
                        child: Text(
                          '${room.playerCount}/4',
                          style: const TextStyle(
                            color: AppColors.parchment,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'Phòng của ${room.hostName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('ID: ${room.roomId}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.playerColors[2],
                        ),
                        child: const Text(
                          'Tham gia',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          // Dùng lại logic vào phòng đã có
                          if (myPlayerName != null && myPlayerName.isNotEmpty) {
                            gameService.joinRoom(room.roomId, myPlayerName);
                            // Sau khi gửi yêu cầu, quay lại màn hình lobby để chờ kết quả
                            Navigator.of(context).pop();
                          } else {
                            // Trường hợp này hiếm khi xảy ra
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Lỗi: Tên người chơi không tồn tại.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
