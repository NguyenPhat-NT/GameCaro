import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_service.dart';
import 'services/connection_screen.dart';

void main() {
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
      title: 'Caro Game',
      theme: ThemeData(
        // Bạn có thể thêm theme tùy chỉnh ở đây
        primarySwatch: Colors.blue,
      ),
      home: ConnectionScreen(),
    );
  }
}
