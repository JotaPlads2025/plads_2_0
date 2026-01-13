import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/neon_widgets.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../models/chat_model.dart';
import '../../common/chat_screen.dart';

class StudentMessagesScreen extends StatelessWidget {
  const StudentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Mensajes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: Provider.of<FirestoreService>(context).getUserChats(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.withOpacity(0.5)),
                   const SizedBox(height: 16),
                   const Text('No tienes mensajes aún', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                   const SizedBox(height: 8),
                   const Text('Los chats con tus profesores aparecerán aquí.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherId = chat.participants.firstWhere((p) => p != currentUser.uid, orElse: () => '');
              final otherName = chat.participantNames[otherId] ?? 'Instructor';
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.neonPurple,
                  child: Text(otherName.isNotEmpty ? otherName[0] : '?', style: const TextStyle(color: Colors.white)),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(otherName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    if (chat.lastMessageTime != null)
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: chat.id, otherUserName: otherName, otherUserId: otherId)
                  ));
                },
              );
            },
          );
        }
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
