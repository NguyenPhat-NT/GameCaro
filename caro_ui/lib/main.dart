// caro_ui/lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/game_service.dart';
import 'services/connection_screen.dart'; // Đường dẫn đúng
import 'game_theme.dart';

void main() {
  // THÊM DÒNG LỆNH QUAN TRỌNG NÀY
  WidgetsFlutterBinding.ensureInitialized();

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
