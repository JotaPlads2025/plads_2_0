import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/classes_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/communication_tab.dart';
import 'finance/finance_screen.dart'; 
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import 'academy/my_academy_screen.dart'; 
import '../common/search_classes_screen.dart'; 
import '../common/help_screen.dart';
import '../student/student_main_screen.dart'; // Import Student Main
import '../legal/terms_screen.dart';
import '../legal/privacy_screen.dart';
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../models/notification_model.dart';
import '../../../../models/user_model.dart';
import 'package:plads_2_0/main.dart';
import 'analytics/analytics_tab.dart';

class InstructorHomeScreen extends StatefulWidget {
  const InstructorHomeScreen({super.key});

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen> {
  int _currentIndex = 0;

  // Removed _tabs list to allow dynamic body building
  // final List<Widget> _tabs = ...

  // Titles for the AppBar based on current tab
  final List<String> _titles = [
    'Dashboard',
    'Estadísticas',
    'Mis Clases',
    'Estudiantes',
    'Comunicación',
  ];

  @override
  Widget build(BuildContext context) {
    // Neon accent (reuse or centralized theme later)
    final neonGreen = const Color(0xFF39FF14);
    const neonPurple = Color(0xFFD000FF);

    // Access current theme mode to determine icon
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get User Data
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<UserModel?>(
      stream: authService.user,
      builder: (context, snapshot) {
        final userName = snapshot.data?.displayName ?? 'Instructor';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
                _titles[_currentIndex],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                ),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            iconTheme: IconThemeData(color: neonGreen), // Keep Drawer icon green
            actions: [
              // Theme Toggle
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                color: isDark ? Colors.amber : Colors.grey[800],
                onPressed: () {
                  // Toggle Theme
                   themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
              // Notification Bell
              // Notification Bell with Badge
              StreamBuilder<List<NotificationModel>>(
                stream: Provider.of<NotificationService>(context).getUserNotifications(snapshot.data?.id ?? ''),
                builder: (context, notifSnapshot) {
                  final notifications = notifSnapshot.data ?? [];
                  final unreadCount = notifications.where((n) => !n.isRead).length;

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        color: Theme.of(context).iconTheme.color,
                        onPressed: () {
                           _showNotifications(context, notifications, snapshot.data?.id ?? '');
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
                  );
                }
              ),
            ],
          ),
          drawer: _buildDrawer(context, neonGreen, neonPurple, userName, snapshot.data?.email, snapshot.data?.photoUrl),
          body: Builder(
            builder: (context) {
              switch (_currentIndex) {
                case 0: return DashboardTab(userName: userName);
                case 1: return const AnalyticsTab();
                case 2: return const ClassesTab();
                case 3: return const StudentsTab();
                case 4: return const CommunicationTab();
                default: return const Center(child: Text('Error'));
              }
            }
          ),
          
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed, // Needed for 4+ items
            backgroundColor: Colors.grey.shade900,
            selectedItemColor: neonGreen,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Estadísticas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Clases',
              ),
               BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Alumnos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Comunidad',
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDrawer(BuildContext context, Color primaryNeon, Color secondaryNeon, String userName, String? email, String? photoUrl) {
    return Drawer(
      backgroundColor: Colors.grey.shade900,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo_app.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                GestureDetector( 
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                     backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                    child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  email ?? 'profesor@plads.com',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.person_outline, 'Mi Perfil', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _buildDrawerItem(Icons.search, 'Buscar Clases', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchClassesScreen()));
          }),
          _buildDrawerItem(Icons.business, 'Mi Academia (Pro)', () {
            Navigator.pop(context); // Close Drawer
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAcademyScreen()));
          }, isPremium: true, accentColor: secondaryNeon),
           _buildDrawerItem(Icons.credit_card, 'Planes y Pagos', () {
            Navigator.pop(context); // Close Drawer
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen()));
          }),
          const Divider(color: Colors.grey),
          
          ExpansionTile(
             leading: const Icon(Icons.gavel, color: Colors.white),
             title: const Text('Legales', style: TextStyle(color: Colors.white)),
             iconColor: Colors.white,
             collapsedIconColor: Colors.white,
             childrenPadding: const EdgeInsets.only(left: 20),
             children: [
                ListTile(
                  title: const Text('Términos y Condiciones', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                  },
                ),
                ListTile(
                  title: const Text('Política de Privacidad', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
                  },
                ),
             ],
           ),
          _buildDrawerItem(Icons.settings_outlined, 'Configuraciones', () {
             Navigator.pop(context); // Close Drawer
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          _buildDrawerItem(Icons.help_outline, 'Ayuda y Soporte', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
          }),
          
          const SizedBox(height: 20), // Spacer replacement to avoid flex issues in ListView if not needed
          
          // Switch to Student Mode
          _buildDrawerItem(Icons.switch_account, 'Cambiar a Modo Alumno', () {
             Navigator.pop(context);
             Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMainScreen()));
          }, color: AppColors.neonPurple),

          const SizedBox(height: 8),

           _buildDrawerItem(Icons.logout, 'Cerrar Sesión', () async {
             Navigator.pop(context); // Close drawer first
             try {
               await Provider.of<AuthService>(context, listen: false).signOut();
               // AuthWrapper will detect null user and show LoginScreen automatically
             } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Error al cerrar sesión: $e')),
               );
             }
           }, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isPremium = false, Color? accentColor, Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: isPremium ? accentColor : color),
      title: Text(
        title,
        style: TextStyle(
          color: isPremium ? accentColor : color,
          fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isPremium ? Icon(Icons.star, size: 16, color: accentColor) : null,
      onTap: onTap,
    );
  }

  void _showNotifications(BuildContext context, List<NotificationModel> notifications, String userId) {
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
                    // Could navigate based on n.type/relatedId
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

  Widget _buildNotificationItem(String title, String body, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.neonPurple.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.notifications, color: AppColors.neonPurple, size: 20), 
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, style: const TextStyle(fontSize: 12)),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
