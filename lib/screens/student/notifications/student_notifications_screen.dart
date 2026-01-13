import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/notification_model.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = Provider.of<AuthService>(context).currentUser;
    final notifService = Provider.of<NotificationService>(context);

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<NotificationModel>>(
      stream: notifService.getUserNotifications(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final notifications = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Notificaciones'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all), 
                tooltip: 'Marcar todas como leídas',
                onPressed: () {
                   for (var n in notifications) {
                     if (!n.isRead) notifService.markAsRead(n.id);
                   }
                   ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Todas las notificaciones marcadas como leídas'))
                   );
                }
              ),
            ],
          ),
          body: notifications.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No tienes notificaciones', style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    
                    IconData iconData;
                    Color iconColor;
                    
                    switch (notif.type) {
                      case 'cancel':
                      case 'cancellation':
                        iconData = Icons.cancel;
                        iconColor = Colors.red;
                        break;
                      case 'booking':
                        iconData = Icons.check_circle;
                        iconColor = Colors.green;
                        break;
                      case 'promo':
                        iconData = Icons.campaign;
                        iconColor = AppColors.neonPurple;
                        break;
                      default:
                        iconData = Icons.notifications;
                        iconColor = Colors.blue;
                    }

                    return Dismissible(
                      key: Key(notif.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // Optional: Delete from Firestore? Or just hide?
                        // For now we just mark as read or actually delete if service supported it.
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDark ? Colors.grey[900] : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: iconColor.withOpacity(0.2),
                            child: Icon(iconData, color: iconColor),
                          ),
                          title: Text(
                            notif.title, 
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            )
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(notif.body, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black54)),
                              const SizedBox(height: 8),
                              Text(_formatDate(notif.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                          trailing: notif.isRead 
                              ? null 
                              : Container(
                                  width: 10, 
                                  height: 10, 
                                  decoration: const BoxDecoration(color: AppColors.neonPurple, shape: BoxShape.circle)
                                ),
                          onTap: () {
                             if (!notif.isRead) {
                               notifService.markAsRead(notif.id);
                             }
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      }
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return 'Hace ${diff.inDays} días';
    if (diff.inHours > 0) return 'Hace ${diff.inHours} horas';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes} minutos';
    return 'Ahora';
  }
}
