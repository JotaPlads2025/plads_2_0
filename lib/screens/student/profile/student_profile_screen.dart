import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../common/help_screen.dart'; 
import '../../login_screen.dart'; 
import 'favorite_teachers_screen.dart'; 
import '../../legal/terms_screen.dart';
import '../../legal/privacy_screen.dart';
import '../settings/student_settings_screen.dart'; 
import '../notifications/student_notifications_screen.dart'; 
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';
import '../../../models/access_grant_model.dart';
import 'package:image_picker/image_picker.dart'; // Added
import '../../../services/storage_service.dart'; // Added
import '../../../services/firestore_service.dart'; // Added
import 'dart:math'; // For random color

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  // Key to force FutureBuilder refresh
  Key _futureKey = UniqueKey();

  void _refreshProfile() {
    setState(() {
      _futureKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Use synchronous currentUser to avoid stream hang
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Inicia sesión para ver tu perfil")));
    }
    
    // Use user.reload() to ensure fresh data if needed, or just fetch profile
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<UserModel?>(
      key: _futureKey, // Force rebuild when key changes
      future: firestoreService.getUserProfile(currentUser.uid),
      builder: (context, snapshot) {
        // Handle loading 
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        // Fallback if null (shouldn't happen in auth flow, but safe handling)
        final displayName = user?.displayName ?? 'Estudiante';
        final email = user?.email ?? '';
        final photoUrl = user?.photoUrl; // Nullable
        final bio = user?.bio ?? '¡Listo para bailar!';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Mi Perfil'),
            actions: [
              IconButton(icon: const Icon(Icons.settings), onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSettingsScreen()));
              }),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      // Avatar Logic: Image or Initials
                      _buildAvatar(context, displayName, photoUrl, user?.id ?? ''),
                      const SizedBox(height: 16),
                      Text(displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      if (apiEmail(email)) Text(email, style: const TextStyle(color: Colors.grey)),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(bio, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 24),
                      
                       // Wallet / Credits Card
                       // Wallet / Credits Card (Grid for multiple)
                       // Active Subscriptions / Packs Card
                      if (user?.activeSubscriptions.isNotEmpty ?? false)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tu Billetera de Clases', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  // Optional: Add a small "History" icon or "Clear" debug button if explicitly requested, but user just wants valid data.
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...user!.activeSubscriptions.where((grant) => grant.isActive).map((grant) {
                                final isPack = grant.type == AccessGrantType.pack;
                                final progress = isPack 
                                    ? (grant.remainingClasses ?? 0) / (grant.initialClasses ?? 1) 
                                    : null;
                                    
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.neonPurple.withOpacity(0.3))
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: Text(grant.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                                          if (isPack)
                                            Text('${grant.remainingClasses} clases', style: const TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.bold, fontSize: 12))
                                          else
                                            const Text('Suscripción', style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Logic to display meaningful tags or 'Multidisciplina'
                                      Builder(
                                        builder: (context) {
                                          final isAll = (grant.discipline.toLowerCase() == 'all' || grant.category.toLowerCase() == 'all');
                                          final tags = isAll ? 'Válido para todo' : '${grant.discipline} • ${grant.category}';
                                          return Text(tags, style: const TextStyle(color: Colors.grey, fontSize: 11));
                                        }
                                      ),
                                      const SizedBox(height: 8),
                                      if (isPack && progress != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey.shade800,
                                            valueColor: AlwaysStoppedAnimation<Color>(_getColorForProgress(progress)),
                                            minHeight: 4,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      if (grant.expiryDate != null)
                                        Text('Vence: ${grant.expiryDate!.toString().split(' ')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                    ],
                                  ),
                                );
                              }).toList(),

                              if (user.activeSubscriptions.where((g) => g.isActive).isEmpty)
                                 const Text('No tienes planes activos.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        )
                      else 
                        // Empty State
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(16)
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('No tienes planes activos', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: () => _showEditProfileDialog(context, user, authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                        ),
                        child: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Menu Options
                _buildSectionTitle('Cuenta'),
                _buildMenuTile(context, icon: Icons.credit_card, title: 'Métodos de Pago', onTap: () {}),
                _buildMenuTile(context, icon: Icons.notifications_none, title: 'Notificaciones', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentNotificationsScreen()));
                }),
                 _buildMenuTile(context, icon: Icons.favorite_border, title: 'Mis Favoritos', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteTeachersScreen()));
                 }),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Personalización'),
                _buildMenuTile(context, icon: Icons.auto_awesome, title: 'Mis Intereses', onTap: () {
                   // Pass current interests
                   showDialog(context: context, builder: (context) => _PreferencesDialog(initialInterests: user?.interests ?? []));
                }),
                _buildMenuTile(context, icon: Icons.link, title: 'Redes Sociales', onTap: () {
                    _showSocialOptions(context, user, authService);
                }),

                const SizedBox(height: 24),
                _buildSectionTitle('Soporte'),
                _buildMenuTile(context, icon: Icons.help_outline, title: 'Ayuda y Contacto', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                }),
                _buildMenuTile(context, icon: Icons.info_outline, title: 'Términos y Condiciones', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
                }),
                 _buildMenuTile(context, icon: Icons.privacy_tip_outlined, title: 'Política de Privacidad', onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
                }),

                const SizedBox(height: 40),
                
                // Logout
                 TextButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (_) => const LoginScreen()), 
                        (route) => false
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),
                const Text('Versión 2.0.0 (Beta)', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildAvatar(BuildContext context, String name, String? photoUrl, String uid) {
    return Stack(
      children: [
        // Avatar
        (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.contains('pravatar'))
            ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(photoUrl))
            : CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple,
                child: Text(
                  _getInitials(name),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              
        // Edit Button
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _handleImageUpload(context, uid),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.neonPurple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
  
  String _getInitials(String name) {
    String initials = '';
    final parts = name.trim().split(' ');
    if (parts.isNotEmpty) {
      initials = parts[0][0].toUpperCase();
      if (parts.length > 1) {
        initials += parts[1][0].toUpperCase();
      }
    } else {
      initials = '?';
    }
    return initials;
  }

  Future<void> _handleImageUpload(BuildContext context, String uid) async {
    final picker = ImagePicker();
    // Show Modal Bottom Sheet to choose Gallery or Camera
    final source = await showModalBottomSheet<ImageSource>(
      context: context, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('Cambiar Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.neonPurple),
            title: const Text('Galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.neonPurple),
            title: const Text('Cámara'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 12),
        ],
      )
    );

    if (source == null) return;
    
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;
    
    // Show Loading
    if (context.mounted) {
       showDialog(
         context: context, 
         barrierDismissible: false,
         builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.neonPurple))
       );
    }

    try {
       final storage = Provider.of<StorageService>(context, listen: false);
       final authService = Provider.of<AuthService>(context, listen: false);
       
       final url = await storage.uploadImage(image: image, folder: 'profile_photos/$uid');
       
       await authService.updateUserProfile(uid: uid, photoUrl: url);
       
       if (context.mounted) {
         Navigator.pop(context); // Pop Loading
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
         _refreshProfile(); // <--- Refresh FutureBuilder
       }
    } catch (e) {
       if (context.mounted) {
         Navigator.pop(context); // Pop Loading
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
    }
  }

  bool apiEmail(String email) => email.isNotEmpty;

  Color _getColorForProgress(double progress) {
    if (progress > 0.5) return AppColors.neonGreen;
    if (progress > 0.2) return Colors.amber;
    return Colors.red;
  }

  void _showEditProfileDialog(BuildContext context, UserModel? user, AuthService authService) {
    if (user == null) return;
    
    final nameController = TextEditingController(text: user.displayName);
    final bioController = TextEditingController(text: user.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonPurple)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Bio (Frase, estilo, etc)',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonPurple)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await authService.updateUserProfile(
                  uid: user.id,
                  displayName: nameController.text.trim(),
                  bio: bioController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
      ),
    );
  }

  void _showSocialOptions(BuildContext context, UserModel? user, AuthService authService) {
    // Clone map to local variable to allow temporary editing before save
    final Map<String, String> links = Map.from(user?.socialLinks ?? {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, 
            right: 24, 
            top: 24, 
            bottom: MediaQuery.of(context).viewInsets.bottom + 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Redes Sociales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ],
              ),
              const SizedBox(height: 16),
              const Text('Toca para editar tus enlaces', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              
              _buildSocialEditTile(
                context, 
                icon: Icons.facebook, 
                color: Colors.blue, 
                title: 'Facebook', 
                currentValue: links['facebook'],
                onSave: (val) async {
                   if(val.isEmpty) links.remove('facebook'); else links['facebook'] = val;
                   // Update backend
                   await authService.updateUserProfile(uid: user!.id, socialLinks: links);
                   // Update local UI
                   setState(() {});
                }
              ),
              _buildSocialEditTile(
                context, 
                icon: Icons.camera_alt, 
                color: Colors.purple, 
                title: 'Instagram', 
                currentValue: links['instagram'],
                onSave: (val) async {
                   if(val.isEmpty) links.remove('instagram'); else links['instagram'] = val;
                   await authService.updateUserProfile(uid: user!.id, socialLinks: links);
                   setState(() {});
                }
              ),
               _buildSocialEditTile(
                context, 
                icon: Icons.music_note, 
                color: Colors.black, 
                title: 'TikTok', 
                currentValue: links['tiktok'],
                onSave: (val) async {
                   if(val.isEmpty) links.remove('tiktok'); else links['tiktok'] = val;
                   await authService.updateUserProfile(uid: user!.id, socialLinks: links);
                   setState(() {});
                }
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialEditTile(BuildContext context, {
    required IconData icon, 
    required Color color, 
    required String title, 
    String? currentValue,
    required Function(String) onSave,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      subtitle: Text(currentValue ?? 'Sin vincular', style: TextStyle(color: currentValue != null ? Colors.black87 : Colors.grey)),
      trailing: const Icon(Icons.edit, size: 16, color: Colors.grey),
      onTap: () {
        // Show small dialog to edit specific link
        final controller = TextEditingController(text: currentValue);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Editar $title'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Usuario o URL de $title'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  onSave(controller.text.trim());
                  Navigator.pop(ctx);
                  // Force rebuild/refresh could be handled by stream logic automatically
                  // If we need to refresh the bottom sheet, we might need a stateful widget there.
                  // For now, simpler to close dialog and rely on backend update -> steam. 
                  // But closing the bottom sheet is jarring. 
                  // Because StreamBuilder is at top level, the bottom sheet might not rebuild instantly unless it listens too.
                  // For UX improvement, using Stateful Widget for BottomSheet is better.
                  // But for speed, let's just close modal for now or acknowledge update.
                }, 
                child: const Text('Guardar')
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.neonPurple.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.neonPurple, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _PreferencesDialog extends StatefulWidget {
  final List<String> initialInterests;
  const _PreferencesDialog({required this.initialInterests});

  @override
  State<_PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<_PreferencesDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialInterests);
  }

  final Map<String, List<String>> _categories = {
    'Baile': ['Salsa', 'Bachata', 'Kizomba', 'Ballet', 'Urbano', 'Tango', 'K-pop', 'Twerk', 'Pole Dance', 'Reggaeton', 'Flamenco', 'Breakdance'],
    'Fitness': ['Yoga', 'Pilates', 'Funcional', 'Crossfit', 'Zumba', 'Calistenia', 'OCR', 'Patinaje'],
    'Arte': ['Pintura', 'Teatro', 'Canto', 'Música', 'Fotografía'],
    'Salud': ['Nutrición', 'Kinesiología', 'Psicología Dep.', 'Meditación'],
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mis Intereses'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona tus áreas de interés.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              
              ..._categories.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                   tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 16),
                  initiallyExpanded: entry.key == 'Baile', 
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value.map((option) {
                          final isSelected = _selected.contains(option);
                          return FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selected.add(option);
                                } else {
                                  _selected.remove(option);
                                }
                              });
                            },
                            selectedColor: AppColors.neonPurple.withOpacity(0.2),
                            checkmarkColor: AppColors.neonPurple,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            // Save logic
             final authService = Provider.of<AuthService>(context, listen: false);
             final user = authService.currentUser;
             if (user != null) {
                await authService.updateUserProfile(uid: user.uid, interests: _selected.toList());
             }
             if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
