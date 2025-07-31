import 'package:flutter/material.dart';
import 'game_theme.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const CaroGameApp());
}

class CaroGameApp extends StatelessWidget {
  const CaroGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Caro 4 Người',
      theme: gameTheme, // Sử dụng theme đã định nghĩa
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
