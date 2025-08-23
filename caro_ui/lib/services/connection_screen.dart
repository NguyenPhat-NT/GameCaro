// File: caro_ui/lib/services/connection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/lobby_screen.dart';
import 'network_service.dart';
import 'game_service.dart';
import '../game_theme.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = 'phatnt.ddns.net';
    _portController.text = '47382';
  }

  void _connectToServer() async {
    setState(() {
      _isLoading = true;
    });

    // Reset lại toàn bộ state cũ trước khi kết nối mới
    context.read<GameService>().resetStateForNewConnection();

    final String ip = _ipController.text.trim();
    final int? port = int.tryParse(_portController.text.trim());

    if (port == null) {
      _showErrorDialog("Lỗi", "Cổng (Port) phải là một con số.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final networkService = NetworkService();
    bool success = await networkService.connect(ip, port);

    if (!mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LobbyScreen()));
    } else {
      _showErrorDialog(
        "Kết nối thất bại",
        "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại IP/Port và trạng thái máy chủ.",
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.parchment,
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Đã hiểu",
                  style: TextStyle(color: AppColors.ink),
                ),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.woodFrame,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.ink.withOpacity(0.5),
                width: 2,
              ),
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "CARO ONLINE",
                  style: textTheme.headlineSmall?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: "Địa chỉ IP Máy chủ",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: "Cổng",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.ink)
                    : ElevatedButton(
                      onPressed: _connectToServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.parchment,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("Kết nối"),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
