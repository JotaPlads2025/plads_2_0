import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final List<String> currentStyles;
  final bool isCoaching;
  final String? currentPhotoUrl; // Add this

  const EditProfileScreen({
    super.key, 
    required this.currentName,
    required this.currentBio,
    required this.currentStyles,
    required this.isCoaching,
    this.currentPhotoUrl, // Add this
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late List<String> _selectedStyles;
  late bool _isCoaching;
  String? _newPhotoUrl; // Add this to track changes

  // ... (keeping _allStyles list same)
  final List<String> _allStyles = [
    'Bachata', 'Salsa', 'Kizomba', 'Zouk', 'Reggaeton', 
    'Hip-Hop', 'Ballet', 'Contemporáneo', 'Tango',
    'Fitness', 'Calistenia', 'Pilates', 'CrossFit', 'Yoga',
    'Entrenamiento Funcional', 'Zumba', 'Actividad Física', 'Salud'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _bioController = TextEditingController(text: widget.currentBio);
    _selectedStyles = List.from(widget.currentStyles);
    _isCoaching = widget.isCoaching;
    _newPhotoUrl = widget.currentPhotoUrl; // Initialize
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: () {
               // Save and Pop
               Navigator.pop(context, {
                 'name': _nameController.text,
                 'bio': _bioController.text,
                 'styles': _selectedStyles,
                 'isCoaching': _isCoaching,
                 'photoUrl': _newPhotoUrl, // Return the URL
               });
            }, 
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold))
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Edit (Visual Only)
            // Avatar Edit
            Center(
              child: Stack(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _newPhotoUrl != null ? NetworkImage(_newPhotoUrl!) : null,
                    child: _newPhotoUrl == null 
                      ? Text(_nameController.text.isNotEmpty ? _nameController.text[0] : '?', style: const TextStyle(fontSize: 40, color: Colors.grey))
                      : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _handleImageUpload(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFFD000FF), shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre Público',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Biografía', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey.withOpacity(0.3)),
                 borderRadius: BorderRadius.circular(12),
                 color: theme.cardTheme.color,
               ),
               child: Column(
                 children: [
                   TextField(
                     controller: _bioController,
                     maxLines: 5,
                     decoration: const InputDecoration(
                       border: InputBorder.none, 
                       hintText: 'Cuentale a tus alumnos sobre ti...'
                     ),
                   ),
                   const Divider(),
                   // AI Assist Button
                   TextButton.icon(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Generando bio con IA... (Próximamente)')));
                      },
                      icon: const Icon(Icons.auto_awesome, color: Color(0xFFD000FF)),
                      label: const Text('Mejorar con IA', style: TextStyle(color: Color(0xFFD000FF))),
                   )
                 ],
               ),
            ),

            const SizedBox(height: 24),
            const Text('Estilos y Especialidades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 1. Ensure all currently selected styles are shown, even if not in the default list
                ..._selectedStyles.where((s) => !_allStyles.contains(s)).map((style) {
                   return _buildChip(style, true);
                }),
                // 2. Show default list (checking if they are selected)
                ..._allStyles.map((style) {
                  final isSelected = _selectedStyles.contains(style);
                  return _buildChip(style, isSelected);
                }),
              ],
            ),

            const SizedBox(height: 24),
            // Coaching Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Realizo Coaching Personalizado', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Aparecerá una insignia verificada en tu perfil.'),
              activeColor: const Color(0xFF39FF14),
              value: _isCoaching,
              onChanged: (val) {
                setState(() => _isCoaching = val);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String style, bool isSelected) {
    return FilterChip(
      label: Text(style),
      selected: isSelected,
      selectedColor: const Color(0xFFD000FF).withOpacity(0.2),
      checkmarkColor: const Color(0xFFD000FF),
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedStyles.add(style);
          } else {
            _selectedStyles.remove(style);
          }
        });
      },
    );
  }

  Future<void> _handleImageUpload(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo foto...')));
    }

    try {
       final authService = Provider.of<AuthService>(context, listen: false);
       final storage = Provider.of<StorageService>(context, listen: false);
       final user = authService.currentUser;
       
       if (user != null) {
          final url = await storage.uploadImage(image: image, folder: 'profile_photos/${user.uid}');
          
          // Only update local state, let "Guardar" handle the Firestore update to avoid race conditions
          setState(() => _newPhotoUrl = url);

          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto subida (Dale a Guardar)')));
          }
       }
    } catch (e) {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
    }
  }
}
