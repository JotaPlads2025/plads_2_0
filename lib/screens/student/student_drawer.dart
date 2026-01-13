import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart'; // Added UserModel
import '../instructor/instructor_home_screen.dart'; // Import Instructor Home
import '../common/help_screen.dart';
import '../common/about_screen.dart'; 
import 'settings/student_settings_screen.dart'; 
import 'notifications/student_notifications_screen.dart'; 
import 'communication/student_messages_screen.dart'; 
import '../legal/terms_screen.dart';
import '../legal/privacy_screen.dart';


class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    return Drawer(
      child: StreamBuilder<UserModel?>(
        stream: authService.user, // Listen to stream
        builder: (context, snapshot) {
          final user = snapshot.data;
          final isInstructor = user?.role == 'instructor';

          return Column(
            children: [
              UserAccountsDrawerHeader(
                 decoration: const BoxDecoration(
                   gradient: LinearGradient(
                     colors: [Colors.black, Colors.deepPurple],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                 ),
                 currentAccountPicture: CircleAvatar(
                    backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!) 
                        : null,
                    child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                        ? Text(
                            (user?.displayName ?? 'S').isNotEmpty ? (user?.displayName ?? 'S').substring(0, 1).toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                 ),
                 accountName: Text(user?.displayName ?? 'Estudiante', style: const TextStyle(fontWeight: FontWeight.bold)),
                 accountEmail: Text(user?.email ?? 'student@plads.cl'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configuración'),
                subtitle: const Text('Tema oscuro, idioma'),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSettingsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notificaciones'),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Mensajes'),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentMessagesScreen()));
                },
              ),
              const Divider(),
              
              // Helper Links
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ayuda y Soporte'),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Acerca de Plads'),
                onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                },
              ),
              ExpansionTile(
                leading: const Icon(Icons.gavel),
                title: const Text('Legales'),
                childrenPadding: const EdgeInsets.only(left: 20),
                children: [
                   ListTile(
                    title: const Text('Términos y Condiciones'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                    },
                  ),
                  ListTile(
                    title: const Text('Política de Privacidad'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
                    },
                  ),
                ],
              ),
              
              const Spacer(),
              
              // CONDITIONAL: Switch back to Instructor
              if (isInstructor) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: AppColors.neonGreen),
                    title: const Text('Volver a Modo Instructor', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate reset to ensure clean state
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (_) => const InstructorHomeScreen()),
                        (route) => false
                      );
                    },
                  ),
                ),
            ],
          );
        }
      ),
    );
  }
}
