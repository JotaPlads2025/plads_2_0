import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/neon_widgets.dart';
import 'edit_profile_screen.dart';
import '../../legal/terms_screen.dart'; 
import '../../legal/privacy_screen.dart';
import '../finance/finance_screen.dart'; 
import 'package:provider/provider.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // We no longer need local state for profile data as it comes from the stream

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    // Use synchronous currentUser to avoid stream hang
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Sesión no iniciada"));
    }

    return FutureBuilder<UserModel?>(
      future: firestoreService.getUserProfile(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
           return const Center(child: Text("Error al cargar perfil"));
        }
        
        final user = snapshot.data!;
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme, user),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 1. Header & Info
                _buildHeader(theme, user, firestoreService),
                
                const SizedBox(height: 24),
                
                // 2. Video Gallery (PRIORITY)
                _buildVideoGallery(theme),

                const SizedBox(height: 24),

                // 3. Details (Bio, Specialities, Socials)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Socials
                      _buildSocialsCard(theme, user, firestoreService),
                      const SizedBox(height: 16),

                      // Specialities
                      _buildInfoCard(
                        theme, 
                        title: 'Especialidades', 
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estilos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: user.interests.map((s) => Chip(label: Text(s), backgroundColor: theme.scaffoldBackgroundColor)).toList(),
                            ),
                            if (user.interests.isEmpty)
                               const Text('No has añadido estilos aún.', style: TextStyle(color: Colors.grey, fontSize: 12)),

                            const Divider(height: 24),
                            // Future: "Publico Objetivo" could be another field in UserModel
                            const Text('Público Objetivo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                                  spacing: 8,
                                  children: ['Principiantes', 'General'].map((a) => Chip(label: Text(a), backgroundColor: theme.scaffoldBackgroundColor)).toList(),
                            ),
                            
                             // Future: "isCoaching" could be a field in UserModel
                             const Divider(height: 24),
                             Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: const [
                                   Icon(Icons.check_circle, size: 16, color: Colors.green),
                                   SizedBox(width: 8),
                                   Text('Ofrece Coaching Personalizado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                 ],
                               ),
                             )
                          ],
                        )
                      ),
                      const SizedBox(height: 16),

                      // Bio
                      _buildInfoCard(
                        theme, 
                        title: 'Sobre Mí', 
                        content: Text(
                          user.bio ?? 'Sin biografía. ¡Cuéntale a tus alumnos sobre ti!', 
                          style: TextStyle(color: Colors.grey.shade400, height: 1.5)
                        )
                      ),
                      const SizedBox(height: 16),
                      
                      // Reviews Placeholder
                       _buildInfoCard(
                        theme, 
                        title: 'Reseñas Verificadas', 
                        iconAction: Icons.verified, 
                        content: Column(
                          children: [
                            const Icon(Icons.star_border, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('Aún no tienes reseñas.', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              'Solo los alumnos que marquen asistencia podrán dejar una reseña verificada.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.neonGreen.withOpacity(0.8)),
                            )
                          ],
                        )
                      ),
                       const SizedBox(height: 16),
                       
                       // Legal Section
                       _buildInfoCard(
                        theme,
                        title: 'Legales',
                        content: Column(
                          children: [
                            ListTile(
                              title: const Text('Términos y Condiciones'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('Política de Privacidad'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                            ),
                          ],
                        )
                       ),
                       const SizedBox(height: 24),

                      // Upgrade Plan CTA
                      _buildUpgradeCard(context),
                       const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  AppBar _buildAppBar(ThemeData theme, UserModel user) {
      return AppBar(
        title: const Text('Mi Perfil Público'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () { 
                // Share functionality 
            }, 
          )
        ],
      );
  }

  Widget _buildHeader(ThemeData theme, UserModel user, FirestoreService firestoreService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null 
                  ? Text(user.displayName.isNotEmpty ? user.displayName[0] : 'U', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey))
                  : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.neonPurple, shape: BoxShape.circle),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(user.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Instructor', style: TextStyle(color: AppColors.neonGreen, fontWeight: FontWeight.w500)), // Role
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
              Icon(Icons.star, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Text('(5.0)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                // Navigate to Edit Mode with REAL DATA
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => EditProfileScreen(
                    currentName: user.displayName, 
                    currentBio: user.bio ?? '', 
                    currentStyles: user.interests,
                    isCoaching: true, // Default for now, add field if needed
                    currentPhotoUrl: user.photoUrl, // PASS CURRENT PHOTO
                  ))
                );
                
                if (result != null) {
                   // Update User in Firestore
                   UserModel updatedUser = UserModel(
                      id: user.id,
                      email: user.email,
                      displayName: result['name'],
                      role: user.role,
                      createdAt: user.createdAt,
                      acceptedTerms: user.acceptedTerms,
                      interests: List<String>.from(result['styles']),
                      bio: result['bio'],
                      photoUrl: result['photoUrl'], // SAVE NEW PHOTO (or existing if unchanged)
                      socialLinks: user.socialLinks, // Preserve existing
                   );
                   await firestoreService.updateUser(updatedUser);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textTheme.bodyLarge?.color,
                side: BorderSide(color: Colors.grey.shade800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVideoGallery(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Galería de Videos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: (){}, icon: const Icon(Icons.add_circle, color: AppColors.neonPurple)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
               // Video 1 (Mock)
               _buildVideoThumbnail(isAdd: false),
               _buildVideoThumbnail(isAdd: false),
               // Add Placeholder
               _buildVideoThumbnail(isAdd: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail({required bool isAdd}) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isAdd ? Colors.grey.shade900 : AppColors.neonPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Center(
        child: isAdd 
         ? Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: const [
               Icon(Icons.video_call, color: Colors.grey, size: 32),
               SizedBox(height: 8),
               Text('Subir Video', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
             ],
           )
         : Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
             child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
           ),
      ),
    );
  }

  Widget _buildSocialsCard(ThemeData theme, UserModel user, FirestoreService firestoreService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text('Redes Sociales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               // The "Editar" button now triggers the modal
               TextButton(
                 onPressed: () => _showEditSocialsSheet(context, user, firestoreService), 
                 child: const Text('Editar', style: TextStyle(fontSize: 12, color: AppColors.neonPurple))
               ),
             ],
           ),
           const SizedBox(height: 12),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: [
               _buildSocialIcon(theme, FontAwesomeIcons.instagram, 'Instagram', user.socialLinks['instagram']?.isNotEmpty ?? false, Colors.purpleAccent, user.socialLinks['instagram']), 
               _buildSocialIcon(theme, FontAwesomeIcons.tiktok, 'TikTok', user.socialLinks['tiktok']?.isNotEmpty ?? false, Colors.pinkAccent, user.socialLinks['tiktok']), 
               _buildSocialIcon(theme, FontAwesomeIcons.facebook, 'Facebook', user.socialLinks['facebook']?.isNotEmpty ?? false, Colors.blue, user.socialLinks['facebook']), 
               _buildSocialIcon(theme, FontAwesomeIcons.whatsapp, 'WhatsApp', user.socialLinks['whatsapp']?.isNotEmpty ?? false, Colors.green, user.socialLinks['whatsapp']), 
               _buildSocialIcon(theme, FontAwesomeIcons.globe, 'Web', user.socialLinks['web']?.isNotEmpty ?? false, Colors.cyan, user.socialLinks['web']), 
             ],
           )
        ],
      ),
    );
  }

  void _showEditSocialsSheet(BuildContext context, UserModel user, FirestoreService firestoreService) {
    final igCtrl = TextEditingController(text: user.socialLinks['instagram'] ?? '');
    final tkCtrl = TextEditingController(text: user.socialLinks['tiktok'] ?? '');
    final fbCtrl = TextEditingController(text: user.socialLinks['facebook'] ?? '');
    final waCtrl = TextEditingController(text: user.socialLinks['whatsapp'] ?? '');
    final wbCtrl = TextEditingController(text: user.socialLinks['web'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar Redes Sociales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Agrega los links a tus perfiles para que tus alumnos te sigan.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            _buildSocialInput(igCtrl, 'Link de Instagram', FontAwesomeIcons.instagram, Colors.purpleAccent),
            const SizedBox(height: 12),
            _buildSocialInput(tkCtrl, 'Link de TikTok', FontAwesomeIcons.tiktok, Colors.pinkAccent),
            const SizedBox(height: 12),
            _buildSocialInput(fbCtrl, 'Link de Facebook', FontAwesomeIcons.facebook, Colors.blue),
            const SizedBox(height: 12),
            _buildSocialInput(waCtrl, 'Link de WhatsApp (https://wa.me/...)', FontAwesomeIcons.whatsapp, Colors.green),
            const SizedBox(height: 12),
            _buildSocialInput(wbCtrl, 'Tu Sitio Web', FontAwesomeIcons.globe, Colors.cyan),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD000FF), foregroundColor: Colors.white),
                onPressed: () async {
                  
                  Map<String, String> newLinks = {
                    'instagram': igCtrl.text,
                    'tiktok': tkCtrl.text,
                    'facebook': fbCtrl.text,
                    'whatsapp': waCtrl.text,
                    'web': wbCtrl.text,
                  };

                  // Update User in Firestore
                   UserModel updatedUser = UserModel(
                      id: user.id,
                      email: user.email,
                      displayName: user.displayName,
                      role: user.role,
                      createdAt: user.createdAt,
                      acceptedTerms: user.acceptedTerms,
                      interests: user.interests,
                      bio: user.bio,
                      socialLinks: newLinks, // New Links
                   );
                   await firestoreService.updateUser(updatedUser);
                   
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar Cambios'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSocialInput(TextEditingController controller, String label, IconData icon, Color color) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
      ),
    );
  }

  Widget _buildSocialIcon(ThemeData theme, IconData icon, String label, bool isActive, Color activeColor, String? url) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (isActive && url != null && url.isNotEmpty) {
           // Launch URL
           launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? activeColor : Colors.transparent),
            ),
            child: Icon(icon, color: isActive ? activeColor : Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              fontSize: 10, 
              color: isActive ? (isDark ? Colors.white : Colors.black87) : Colors.grey
            )
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, {required String title, required Widget content, IconData? iconAction}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (iconAction != null) Icon(iconAction, color: AppColors.neonGreen, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade900, Colors.deepPurple.shade900]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonPurple),
      ),
      child: Column(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          const Text('Tu Plan Actual: Comisión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          NeonButton(
            text: 'Mejorar a Pro', 
            color: AppColors.neonGreen, 
            onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen()));
            }
          )
        ],
      ),
    );
  }
}
