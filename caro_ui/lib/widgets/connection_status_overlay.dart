// lib/widgets/connection_status_overlay.dart

import 'package:caro_ui/game_theme.dart';
import 'package:caro_ui/services/network_service.dart';
import 'package:flutter/material.dart';

class ConnectionStatusOverlay extends StatelessWidget {
  final Widget child;
  const ConnectionStatusOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Lấy instance của NetworkService (Singleton)
    final networkService = NetworkService();

    // StreamBuilder là một widget đặc biệt, nó sẽ tự động cập nhật
    // giao diện mỗi khi stream có dữ liệu mới.
    return StreamBuilder<bool>(
      // Lắng nghe stream trạng thái kết nối từ NetworkService
      stream: networkService.connectionStatusStream,
      // Giá trị ban đầu, giả định là đang kết nối để không hiển thị overlay khi mới vào app
      initialData: true,
      builder: (context, snapshot) {
        // Lấy trạng thái kết nối từ stream, nếu chưa có thì mặc định là false
        final bool isConnected = snapshot.data ?? false;

        // Dùng Stack để xếp chồng các widget lên nhau
        return Stack(
          children: [
            // Lớp dưới cùng: Luôn hiển thị màn hình chính của ứng dụng
            child,

            // Lớp trên cùng: Chỉ hiển thị lớp phủ khi isConnected là false
            if (!isConnected)
              Positioned.fill(
                child: Container(
                  // Lớp phủ màu đen mờ
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.parchment,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Mất kết nối.\nĐang thử kết nối lại...',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.parchment),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
