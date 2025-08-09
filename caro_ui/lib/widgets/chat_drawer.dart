// File: caro_ui/lib/widgets/chat_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../services/game_service.dart';
import '../game_theme.dart';

class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key});

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    context.read<GameService>().sendChatMessage(_chatController.text);
    _chatController.clear();
    FocusScope.of(context).unfocus(); // Ẩn bàn phím sau khi gửi
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<GameService>();
    final messages = gameService.chatMessages;
    final myPlayerId = gameService.myPlayerId;
    _scrollToBottom();

    return Drawer(
      backgroundColor: AppColors.parchment,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Trò chuyện'),
          backgroundColor: AppColors.woodFrame,
          automaticallyImplyLeading: false,
        ),
        // resizeToAvoidBottomInset: true (đây là giá trị mặc định)
        // Thuộc tính này sẽ tự động co body của Scaffold lại để chừa không gian cho bàn phím
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _ChatMessageBubble(
                    message: message,
                    isMe: message.playerId == myPlayerId,
                  );
                },
              ),
            ),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    // --- THAY ĐỔI CHÍNH Ở ĐÂY ---
    // Chúng ta không cần Padding động nữa, chỉ cần một Padding đơn giản để làm đẹp.
    // Scaffold sẽ tự động đẩy cả Column lên khi bàn phím xuất hiện.
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.background,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.parchment,
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp _ChatMessageBubble giữ nguyên không thay đổi
class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatMessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? Theme.of(context).primaryColor.withOpacity(0.5) : AppColors.woodFrame.withOpacity(0.3);

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 40.0 : 0.0,
        right: isMe ? 0.0 : 40.0,
        top: 4.0,
        bottom: 4.0,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            isMe ? 'Bạn' : message.playerName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(message.message),
          ),
        ],
      ),
    );
  }
}