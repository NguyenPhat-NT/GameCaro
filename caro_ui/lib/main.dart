import 'package:flutter/material.dart';
import 'game_theme.dart';
import 'services/game_service.dart';
import 'screens/lobby_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameService(),
      child: const CaroGameApp(),
    ),
  );
}

class CaroGameApp extends StatelessWidget {
  const CaroGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Caro 4 Người',
      theme: gameTheme,
      // Bắt đầu với màn hình chờ (Lobby)
      home: const LobbyScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
