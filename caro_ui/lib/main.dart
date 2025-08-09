// caro_ui/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Thư viện cần thiết
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/game_service.dart';
import 'services/connection_screen.dart';
import 'game_theme.dart';

// --- THAY ĐỔI 1: Thêm async và các lệnh khóa màn hình ---
Future<void> main() async {
  // Đảm bảo các thành phần Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // Khóa ứng dụng chỉ ở chế độ ngang
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (context) => GameService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caro Game Online',
      theme: gameTheme.copyWith(
        textTheme: GoogleFonts.medievalSharpTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      ),
      home: const ConnectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}