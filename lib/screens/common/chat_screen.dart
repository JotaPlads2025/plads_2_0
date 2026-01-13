import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neon_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    if (currentUser == null) return;

    Provider.of<FirestoreService>(context, listen: false)
        .sendMessage(widget.chatId, currentUser.uid, _messageController.text.trim());
    
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 1,
      ),
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: Provider.of<FirestoreService>(context).getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error al cargar mensajes'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final messages = snapshot.data!;
                if (messages.isEmpty) return const Center(child: Text('Inicia la conversación...'));

                return ListView.builder(
                  reverse: true, // Show newest at bottom (using standard reverse list)
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;
                    return _buildMessageBubble(msg, isMe, isDark);
                  },
                );
              },
            ),
          ),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.neonPurple : (isDark ? Colors.grey.shade800 : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
             if (!isDark) BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2, spreadRadius: 1)
          ]
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                filled: true,
                fillColor: isDark ? Colors.black : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.neonGreen,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: _sendMessage,
            ),
          )
        ],
      ),
    );
  }
}
