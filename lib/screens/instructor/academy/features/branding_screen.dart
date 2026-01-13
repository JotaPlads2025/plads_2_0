import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../widgets/neon_widgets.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../services/storage_service.dart';
import '../../../../../services/academy_service.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  final _formKey = GlobalKey<FormState>();
  late Color _primaryColor;
  late TextEditingController _subdomainController;
  late TextEditingController _addressController;
  bool _isLoading = false;
  
  final List<Color> _presetColors = [
    const Color(0xFFD000FF), // Primary Neon
    const Color(0xFF39FF14), // Secondary Neon
    Colors.blueAccent,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
  ];

  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    final academy = Provider.of<AcademyService>(context, listen: false).currentAcademy;
    _primaryColor = academy?.primaryColor ?? const Color(0xFFD000FF);
    _subdomainController = TextEditingController(text: academy?.subdomain ?? '');
    _addressController = TextEditingController(text: academy?.address ?? '');
    _logoUrl = academy?.logoUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final academyId = Provider.of<AcademyService>(context, listen: false).currentAcademy!.id;
      final url = await storage.uploadImage(image: image, folder: 'academies/$academyId/branding');
      
      setState(() {
        _logoUrl = url;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo subido. No olvides guardar los cambios.')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _subdomainController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final academy = Provider.of<AcademyService>(context).currentAcademy;

    if (academy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No se ha encontrado la academia')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Personalizar Marca'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(theme, 'Logotipo', 'Sube el logo de tu academia (PNG transparente recomendado).'),
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: _primaryColor, width: 3),
                        image: _logoUrl != null 
                            ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover)
                            : const DecorationImage(
                                image: AssetImage('assets/images/logo_app.png'),
                                fit: BoxFit.contain,
                              )
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: _primaryColor,
                        radius: 18,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: _isLoading 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _isLoading ? null : _pickImage,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSection(theme, 'Color Principal', 'Este color se usará en tus botones y enlaces públicos.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetColors.map((color) {
                  final isSelected = _primaryColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _primaryColor = color),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3) : null,
                        boxShadow: [
                           if (isSelected) BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)
                        ]
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              _buildSection(theme, 'Dominio Web', 'Tu dirección única en Plads.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('plads.com/', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    Expanded(
                      child: TextFormField(
                        controller: _subdomainController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'tu-academia',
                        ),
                        // Sanitize input as user types
                        onChanged: (val) {
                          String slug = val.toLowerCase();
                          slug = slug.replaceAll('ñ', 'n').replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');
                          slug = slug.replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
                          
                          // Only update if changed to avoid cursor jumping issues (basic implementation)
                          if (val != slug) {
                            _subdomainController.value = TextEditingValue(
                              text: slug,
                              selection: TextSelection.collapsed(offset: slug.length),
                            );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                    ),
                    if (_subdomainController.text.isNotEmpty)
                      const Icon(Icons.check_circle, color: Colors.green)
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildSection(theme, 'Dirección', 'La dirección física de tu academia.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Ej: Calle Falsa 123, Ciudad, País',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección no puede estar vacía';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),
              NeonButton(
                text: _isLoading ? 'Guardando...' : 'Guardar Cambios',
                color: _primaryColor,
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    
                    await Provider.of<AcademyService>(context, listen: false).updateBranding(
                      academyId: academy.id,
                      address: _addressController.text,
                      subdomain: _subdomainController.text,
                      primaryColor: _primaryColor,
                      logoUrl: _logoUrl, // Pass logical URL
                    );
                    
                    if (mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marca actualizada correctamente')));
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
