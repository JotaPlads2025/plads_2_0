import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart'; // Add Intl
import '../../../../models/class_model.dart'; // Add ClassModel
import '../../../services/firestore_service.dart'; // Add FirestoreService
import '../../../../theme/app_theme.dart';
import '../../../../services/auth_service.dart';
import '../../common/search_classes_screen.dart';
import '../student_drawer.dart';
import '../../../../models/notification_model.dart'; // Add NotificationModel
import '../../../../services/notification_service.dart'; // Add NotificationService
import '../../common/qr_scanner_screen.dart'; // Corrected Path
import '../../../../models/user_model.dart'; // Added UserModel import

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<UserModel?>(
      stream: authService.user,
      initialData: authService.currentUserModel,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final userName = user?.displayName ?? 'Estudiante';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Inicio'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              StreamBuilder<List<NotificationModel>>(
                stream: Provider.of<NotificationService>(context).getUserNotifications(user?.id ?? ''),
                builder: (context, notifSnapshot) {
                  final notifications = notifSnapshot.data ?? [];
                  final unreadCount = notifications.where((n) => !n.isRead).length;

                  return Row(
                    children: [
                       IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Escanear Clase', 
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()));
                        },
                      ),
                      Stack(
                        children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {
                           _showNotifications(context, notifications);
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ],
                  );
                }
              ),
            ],
          ),
          drawer: const StudentDrawer(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¡Hola, $userName!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('¿Estás listo para moverte?', style: TextStyle(color: Colors.grey)), // Updated message
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code, size: 30),
                      color: AppColors.neonPurple,
                      tooltip: 'Mi Pase de Acceso',
                      onPressed: () => _showMyQR(context, user),
                    )
                  ],
                ),
                const SizedBox(height: 30),

                const SizedBox(height: 30),

                // Hero Ticket (Next Class)
                const Text('Tu Próxima Clase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Real Data Stream
                if (user == null)
                   const Center(child: CircularProgressIndicator())
                else
                   StreamBuilder<List<ClassModel>>(
                     stream: Provider.of<FirestoreService>(context).getStudentClasses(user.id),
                     builder: (context, classSnapshot) {
                        if (classSnapshot.connectionState == ConnectionState.waiting) {
                           return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                        }
                        final classes = classSnapshot.data ?? [];
                        if (classes.isEmpty) return _buildEmptyTicket(context);
                        
                        // Show the first upcoming class
                        return _buildTicketCard(context, classes.first);
                     }
                   ),

                const SizedBox(height: 32),
                
                // Quick Categories
                const Text('Explorar por Estilo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryItem(context, 'Salsa', Icons.music_note, Colors.orange),
                      _buildCategoryItem(context, 'Bachata', Icons.favorite, Colors.pink),
                      _buildCategoryItem(context, 'Kizomba', Icons.groups, Colors.purple),
                      _buildCategoryItem(context, 'Urbano', Icons.speaker, Colors.blue),
                      _buildCategoryItem(context, 'Ballet', Icons.accessibility, Colors.teal),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // AI Coach Teaser
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.black, Colors.deepPurple.shade900]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neonPurple.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                       const Icon(Icons.auto_awesome, color: AppColors.neonPurple, size: 40),
                       const SizedBox(height: 12),
                       const Text('Plads AI Coach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 8),
                       const Text(
                         'Pronto podrás obtener recomendaciones personalizadas basadas en tus metas y estilo de baile favorito.',
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey, fontSize: 12),
                       ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildTicketCard(BuildContext context, ClassModel cls) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppColors.neonPurple.withOpacity(0.8), Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.neonPurple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern (Circles)
          Positioned(right: -20, top: -20, child: Icon(Icons.circle, size: 150, color: Colors.white.withOpacity(0.05))),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _getDateLabel(cls.date) + ', ${cls.startTime}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const Icon(Icons.confirmation_number, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 20),
                Text(cls.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('con ${cls.instructorName}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 24),
                Row(
                  children: [
                     const Icon(Icons.location_on, color: AppColors.neonGreen, size: 20),
                     const SizedBox(width: 8),
                     Expanded(child: Text(cls.location, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                     ElevatedButton.icon(
                       onPressed: () {
                         _showQRModal(context, cls.id, Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '');
                       },
                       icon: const Icon(Icons.qr_code, size: 18),
                       label: const Text('Entrada'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.black,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                       ),
                     )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTicket(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No tienes clases agendadas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Busca una clase y comienza a bailar.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchClassesScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buscar Clases'),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate with pre-filled search (future enhancement)
         Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchClassesScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showQRModal(BuildContext context, String classId, String userId) {
    // Generate Unique Ticket ID
    final ticketId = '${classId}_$userId';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tu Pase de Acceso', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Muestra este código al instructor', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            QrImageView(
              data: ticketId,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 32),
            const Text('Disfruta tu clase! 💃🕺', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
             Text('ID: ${ticketId.substring(0, 8)}...', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  void _showMyQR(BuildContext context, UserModel? user) {
    if (user == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mi Pase GM', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              QrImageView(
                data: 'plads_user:${user.id}',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(user.displayName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Muestra este código al instructor', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar')
              )
            ],
          ),
        ),
      )
    );
  }

  void _showNotifications(BuildContext context, List<NotificationModel> notifications) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: const Text('Notificaciones'),
          content: SizedBox(
            width: double.maxFinite,
            child: notifications.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No tienes notificaciones nuevas.', textAlign: TextAlign.center),
                )
              : ListView.separated(
              shrinkWrap: true,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: n.isRead ? Colors.grey.withOpacity(0.1) : AppColors.neonPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications, 
                      color: n.isRead ? Colors.grey : AppColors.neonPurple, 
                      size: 20
                    ), 
                  ),
                  title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                  subtitle: Text(n.body, style: const TextStyle(fontSize: 12)),
                  trailing: n.isRead ? null : const Icon(Icons.circle, color: AppColors.neonGreen, size: 8),
                  onTap: () {
                    // Mark as read
                    Provider.of<NotificationService>(context, listen: false).markAsRead(n.id);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cerrar', style: TextStyle(color: Colors.grey))
            ),
          ],
        );
      },
    );
  }
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = DateTime(date.year, date.month, date.day);

    if (upcoming.isAtSameMomentAs(today)) {
      return 'HOY';
    } else if (upcoming.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'MAÑANA';
    } else {
      return DateFormat('dd MMM', 'es').format(date);
    }
  }
}
