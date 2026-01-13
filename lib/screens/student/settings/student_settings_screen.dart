import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import 'package:plads_2_0/main.dart'; 
import '../../common/about_screen.dart'; 
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart'; // Import UserModel

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: authService.user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          
          // Defaults if not set
          final settings = user?.notificationSettings ?? {};
          final subsNotifications = settings['subscriptions'] as bool? ?? true;
          final reminderTime = settings['reminderTime'] as String? ?? '1 hora antes';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Appearance Section
              _buildSectionHeader('Apariencia'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text('Modo Oscuro', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cambia entre tema claro y oscuro'),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.neonPurple),
                  value: isDark,
                  activeColor: AppColors.neonPurple,
                  onChanged: (val) {
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
              
              const SizedBox(height: 24),

              // 2. Notifications Section
              _buildSectionHeader('Notificaciones'),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    // Subscriptions
                    SwitchListTile(
                      title: const Text('Suscripciones', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Recibe alertas de tus profesores favoritos'),
                      secondary: const Icon(Icons.favorite, color: Colors.redAccent),
                      value: subsNotifications,
                      activeColor: AppColors.neonPurple,
                      onChanged: (val) async {
                         if (user == null) return;
                         final newSettings = Map<String, dynamic>.from(settings);
                         newSettings['subscriptions'] = val;
                         await authService.updateUserProfile(uid: user.id, notificationSettings: newSettings);
                      },
                    ),
                    const Divider(),
                    
                    // Class Reminders
                    ListTile(
                      leading: const Icon(Icons.alarm, color: Colors.amber),
                      title: const Text('Recordatorio de Clases', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cuando avisarme: $reminderTime'),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: reminderTime,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.neonPurple),
                          items: ['No recibir', '1 hora antes', '6 horas antes', '24 horas antes']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) async {
                             if (user == null || newValue == null) return;
                             final newSettings = Map<String, dynamic>.from(settings);
                             newSettings['reminderTime'] = newValue;
                             await authService.updateUserProfile(uid: user.id, notificationSettings: newSettings);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Información'),
               Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                   children: [
                     ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
                        title: const Text('Acerca de Plads'),
                        subtitle: const Text('Historia, Misión y Equipo'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                        },
                      ),
                      const Divider(),
                      const ListTile(
                        leading: Icon(Icons.android, color: Colors.grey),
                        title: Text('Versión de la App'),
                        trailing: Text('2.0.0 (Beta)', style: TextStyle(color: Colors.grey)),
                      ),
                   ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)
      ),
    );
  }
}
