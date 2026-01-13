import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/neon_widgets.dart';
import '../../../../services/academy_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../models/academy_model.dart';

// Feature Screens
import 'features/branding_screen.dart';
import 'features/staff_screen.dart';
import 'features/marketing_screen.dart';
import 'features/integrations_screen.dart';
import 'features/facilities_screen.dart';
import 'features/academy_schedule_screen.dart';
import '../../common/map_picker_screen.dart'; // Map Picker import
import '../../common/map_picker_screen.dart'; // Map Picker import
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../utils/location_helper.dart';
import '../../../../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File
import 'package:flutter/foundation.dart'; // For kIsWeb

class MyAcademyScreen extends StatefulWidget {
  const MyAcademyScreen({super.key});

  @override
  State<MyAcademyScreen> createState() => _MyAcademyScreenState();
}

class _MyAcademyScreenState extends State<MyAcademyScreen> {
  // Mock State for Pro Check
  bool isPro = true; 
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _subdomainController = TextEditingController();
  
  // New State for Creation
  XFile? _logoImage;
  double? _selectedLat;
  double? _selectedLng;
  String _selectedRegion = 'Metropolitana';
  String _selectedCommune = 'Providencia';

  @override
  void initState() {
    super.initState();
    _loadAcademy();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademy() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    // Optimisation: Try getting current user synchronously first
    final String? uid = authService.currentUser?.uid;
    
    if (uid != null) {
       await Provider.of<AcademyService>(context, listen: false).loadAcademy(uid);
    } else {
       // Fallback to stream if for some reason currentUser is null (rare if guarded)
       final user = await authService.user.first;
       if (user != null) {
         await Provider.of<AcademyService>(context, listen: false).loadAcademy(user.id);
       }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final academyService = Provider.of<AcademyService>(context);
    final academy = academyService.currentAcademy;
    final hasAcademy = academy != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Academia'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
           if (isPro && hasAcademy)
             IconButton(
               icon: const Icon(Icons.settings), 
               onPressed: () {
                 showModalBottomSheet(
                   context: context,
                   backgroundColor: theme.scaffoldBackgroundColor,
                   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                   builder: (context) => Padding(
                     padding: const EdgeInsets.all(24),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('Configuración de Academia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 24),
                         ListTile(
                           leading: const Icon(Icons.delete_forever, color: Colors.red),
                           title: const Text('Eliminar Academia', style: TextStyle(color: Colors.red)),
                           subtitle: const Text('Esta acción no se puede deshacer.'),
                           onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('¿Eliminar Academia?'),
                                  content: const Text('Perderás todos los datos, clases y configuraciones.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true), 
                                      child: const Text('Eliminar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                                    ),
                                  ],
                                )
                              );
                              
                              if (confirm == true) {
                                 if (context.mounted) {
                                   Navigator.pop(context); // Close sheet
                                   setState(() => _isLoading = true);
                                   try {
                                     await Provider.of<AcademyService>(context, listen: false).deleteAcademy(academy!.id);
                                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Academia eliminada.')));
                                   } catch (e) {
                                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                   } finally {
                                     if (mounted) setState(() => _isLoading = false);
                                   }
                                 }
                              }
                           },
                         )
                       ],
                     ),
                   )
                 );
               }
             ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : (isPro 
              ? (hasAcademy ? _buildProDashboard(theme, isDark, academy) : _buildCreateAcademyView(theme))
              : _buildUpgradeView(theme, isDark)),
    );
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoImage = image;
      });
    }
  }

  Widget _buildCreateAcademyView(ThemeData theme) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO PICKER ---
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonPurple.withOpacity(0.5)),
                    image: _logoImage != null 
                        ? DecorationImage(
                             image: kIsWeb ? NetworkImage(_logoImage!.path) : FileImage(File(_logoImage!.path)) as ImageProvider,
                             fit: BoxFit.cover
                          )
                        : null
                  ),
                  child: _logoImage == null 
                     ? Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: const [
                           Icon(Icons.add_a_photo, size: 30, color: AppColors.neonPurple),
                           SizedBox(height: 4),
                           Text("Logo", style: TextStyle(fontSize: 10, color: AppColors.neonPurple))
                         ],
                       )
                     : null,
                ),
              ),
              const SizedBox(height: 24),
              const Text('Crea tu propia Academia', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Centraliza tus clases, alumnos y finanzas bajo tu propia marca.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de tu Academia',
                  hintText: 'Ej: Studio Danza Viva',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                onChanged: (val) {
                   String slug = val.toLowerCase();
                   slug = slug.replaceAll('ñ', 'n').replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u');
                   slug = slug.replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
                   _subdomainController.text = slug;
                },
              ),
              const SizedBox(height: 16),
              
              // --- ADDRESS MAP PICKER ---
              Container(
                 width: double.infinity,
                 decoration: BoxDecoration(
                   color: _selectedLat != null ? AppColors.neonGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: _selectedLat != null ? AppColors.neonGreen : Colors.grey.withOpacity(0.3))
                 ),
                 child: TextButton.icon(
                   icon: Icon(Icons.map, color: _selectedLat != null ? AppColors.neonGreen : Colors.grey),
                   label: Text(
                     _selectedLat != null ? 'Ubicación Seleccionada' : 'Seleccionar Dirección en Mapa',
                     style: TextStyle(color: _selectedLat != null ? AppColors.neonGreen : Colors.grey),
                   ),
                   onPressed: () async {
                      final result = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const MapPickerScreen()) 
                      );
                      
                      if (result != null && result is Map) {
                         // Extract Data
                         final latLng = result['latLng'] as LatLng;
                         final address = result['address'] as String?;
                         final region = result['region'] as String?;
                         final commune = result['commune'] as String?;

                         setState(() {
                            _selectedLat = latLng.latitude;
                            _selectedLng = latLng.longitude;
                            
                            if (address != null && address.isNotEmpty) {
                               _addressController.text = address;
                            }
                            
                            final matchedRegion = LocationHelper.matchRegion(region);
                            if (matchedRegion != null) {
                               _selectedRegion = matchedRegion;
                               
                               final matchedCommune = LocationHelper.matchCommune(matchedRegion, commune);
                               if (matchedCommune != null) _selectedCommune = matchedCommune;
                            }
                         });
                      }
                   },
                 ),
              ),
              if (_selectedLat != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 4, bottom: 8),
                   child: Text('Lat: ${_selectedLat!.toStringAsFixed(4)}, Lng: ${_selectedLng!.toStringAsFixed(4)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                 ),

              const SizedBox(height: 12),
              
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección Comercial',
                  hintText: 'Ej: Av. Providencia 1234',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _subdomainController,
                decoration: const InputDecoration(
                  labelText: 'Subdominio (Link)',
                  prefixText: 'plads.app/',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 24),

              NeonButton(
                text: 'Comenzar ahora', 
                color: AppColors.neonPurple, 
                onPressed: () async {
                   if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
                     setState(() => _isLoading = true);
                     try {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final user = authService.currentUser;
                        if (user != null) {
                           // 1. Upload Logo if present
                           String? logoUrl;
                           if (_logoImage != null) {
                              final storage = Provider.of<StorageService>(context, listen: false); // Ensure Provider exists or use instance
                              logoUrl = await storage.uploadImage(image: _logoImage!, folder: 'academies/${user.uid}/logo');
                           }

                           // 2. Create Academy with new fields
                           await Provider.of<AcademyService>(context, listen: false).createAcademy(
                             instructorId: user.uid,
                             name: _nameController.text,
                             address: _addressController.text,
                             subdomain: _subdomainController.text,
                             primaryColor: AppColors.neonPurple,
                             region: _selectedRegion,
                             commune: _selectedCommune,
                             latitude: _selectedLat,
                             longitude: _selectedLng,
                             logoUrl: logoUrl,
                           );
                           
                           if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Academia creada exitosamente!')));
                           }
                        }
                     } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); 
                     } finally {
                        if (mounted) setState(() => _isLoading = false);
                     }
                   } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa el nombre y dirección')));
                   }
                }
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text('Más información sobre Academias', style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeView(ThemeData theme, bool isDark) {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(32.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.business, size: 80, color: Colors.grey.shade700),
             const SizedBox(height: 24),
             const Text('Mi Academia es una función Pro', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             const Text('Desbloquea branding personalizado, gestión de equipo, dominio propio y herramientas avanzadas de marketing.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 32),
             NeonButton(
               text: 'Mejorar a Pro', 
               color: AppColors.neonPurple, 
               onPressed: () {
                 // Navigate to Plans
               }
             )
           ],
         ),
       ),
     );
  }

  Widget _buildProDashboard(ThemeData theme, bool isDark, AcademyModel academy) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Academy Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                academy.primaryColor.withOpacity(0.8), 
                Colors.black
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: academy.primaryColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: academy.logoUrl != null 
                        ? DecorationImage(image: NetworkImage(academy.logoUrl!), fit: BoxFit.cover)
                        : const DecorationImage(
                            image: AssetImage('assets/images/logo_app.png'), // Placeholder
                            fit: BoxFit.contain
                          )
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(academy.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                            onPressed: () => _showEditAcademyDialog(academy),
                            tooltip: 'Editar Información',
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${academy.address}, ${academy.commune}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('plads.com/${academy.subdomain}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () {}, 
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white, 
                            side: const BorderSide(color: Colors.white54),
                            textStyle: const TextStyle(fontSize: 12)
                          ),
                          child: const Text('Ver página pública')
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Core Features Grid
          const Text('Gestión Profesional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
               _buildFeatureCard(
                 theme, Icons.palette, 'Personalizar Marca', 'Logo, colores y dominio', Colors.pinkAccent,
                 () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandingScreen()))
               ),
               _buildFeatureCard(
                 theme, Icons.people_alt, 'Equipo / Staff', 'Gestiona instructores', Colors.blueAccent,
                 () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffScreen()))
               ),
               _buildFeatureCard(
                 theme, Icons.meeting_room, 'Instalaciones', 'Salas y Recursos', Colors.purpleAccent,
                 () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FacilitiesScreen()))
               ),
               _buildFeatureCard(
                 theme, Icons.calendar_month, 'Agenda Academia', 'Vista global de clases', Colors.teal,
                 () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademyScheduleScreen()))
               ),
               _buildFeatureCard(
                 theme, Icons.campaign, 'Marketing', 'Campañas y Pixels', Colors.orangeAccent,
                 () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingScreen()))
               ),
               _buildFeatureCard(
                 theme, Icons.integration_instructions, 'Integraciones', 'Zoom, Calendar, Zapier', Colors.greenAccent,
                 () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntegrationsScreen()))
               ),
            ],
          ),

          const SizedBox(height: 24),
          
          // Analytics Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Analíticas de Academia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Icon(Icons.bar_chart, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: _StatItem(label: 'Visitas Perfil', value: '0', change: '--')),
                    Expanded(child: _StatItem(label: 'Conversión', value: '0%', change: '--')),
                    Expanded(child: _StatItem(label: 'Leads', value: '0', change: '--')),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeatureCard(ThemeData theme, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: theme.cardTheme.color,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.grey.withOpacity(0.1)),
           boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
           ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }



  void _showEditAcademyDialog(AcademyModel academy) {
    final nameCtrl = TextEditingController(text: academy.name);
    final addressCtrl = TextEditingController(text: academy.address);
    final subdomainCtrl = TextEditingController(text: academy.subdomain);
    
    // Simplified Commune Data (Should be shared constant ideally)
    final Map<String, List<String>> communesByRegion = {
      'Metropolitana': ['Santiago', 'Providencia', 'Las Condes', 'Ñuñoa', 'La Florida', 'Maipú', 'Vitacura', 'La Reina', 'Peñalolén', 'Macul', 'San Miguel', 'Estación Central', 'Recoleta', 'Huechuraba'],
      'Valparaíso': ['Valparaíso', 'Viña del Mar', 'Concón', 'Quilpué', 'Villa Alemana'],
      'Biobío': ['Concepción', 'Talcahuano', 'San Pedro de la Paz', 'Chiguayante'],
      'O\'Higgins': ['Rancagua', 'Machalí'],
      'Maule': ['Talca', 'Curicó'],
    };
    
    String selectedRegion = communesByRegion.containsKey(academy.region) ? academy.region : 'Metropolitana';
    String selectedCommune = academy.commune;
    
    final instaCtrl = TextEditingController(text: academy.socialLinks['instagram']);
    final fbCtrl = TextEditingController(text: academy.socialLinks['facebook']);
    final webCtrl = TextEditingController(text: academy.socialLinks['website']);

    // Local state for coordinates
    double? tempLat = academy.latitude;
    double? tempLng = academy.longitude;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar Información'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text('Datos Generales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 12),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Dirección')),
                  
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRegion,
                    decoration: const InputDecoration(labelText: 'Región'),
                    items: communesByRegion.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedRegion = val!;
                        selectedCommune = communesByRegion[selectedRegion]!.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: communesByRegion[selectedRegion]!.contains(selectedCommune) ? selectedCommune : communesByRegion[selectedRegion]!.first,
                    decoration: const InputDecoration(labelText: 'Comuna'),
                    items: communesByRegion[selectedRegion]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCommune = val!),
                  ),
                  const SizedBox(height: 12),
                  
                  // Map Selection Button for Academy
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: tempLat != null ? AppColors.neonGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tempLat != null ? AppColors.neonGreen : Colors.grey.withOpacity(0.3))
                    ),
                    child: TextButton.icon(
                      icon: Icon(Icons.map, color: tempLat != null ? AppColors.neonGreen : Colors.grey),
                      label: Text(
                        tempLat != null ? 'Ubicación Configurada' : 'Seleccionar Ubicación en Mapa',
                        style: TextStyle(color: tempLat != null ? AppColors.neonGreen : Colors.grey),
                      ),
                      onPressed: () async {
                         final result = await Navigator.push(
                           context, 
                           MaterialPageRoute(builder: (_) => MapPickerScreen(
                             initialPosition: (tempLat != null && tempLng != null) 
                               ? LatLng(tempLat!, tempLng!) 
                               : const LatLng(-33.4489, -70.6693)
                           )) 
                         );
                         
                         if (result != null && result is Map) {
                            // Extract Data
                            final latLng = result['latLng'] as LatLng;
                            final address = result['address'] as String?;
                            final region = result['region'] as String?;
                            final commune = result['commune'] as String?;

                            setDialogState(() {
                               tempLat = latLng.latitude;
                               tempLng = latLng.longitude;
                               
                               if (address != null && address.isNotEmpty) {
                                  addressCtrl.text = address;
                               }
                               
                                // Use LocationHelper
                                final matchedRegion = LocationHelper.matchRegion(region);
                                if (matchedRegion != null && communesByRegion.containsKey(matchedRegion)) {
                                   selectedRegion = matchedRegion;
                                   
                                   final matchedCommune = LocationHelper.matchCommune(matchedRegion!, commune);
                                   if (matchedCommune != null) {
                                      selectedCommune = matchedCommune;
                                   } else {
                                      selectedCommune = communesByRegion[matchedRegion]!.first;
                                   }
                                }
                            });
                         }
                      },
                    ),
                  ),
                  if (tempLat != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 4, bottom: 8),
                       child: Text('Lat: ${tempLat!.toStringAsFixed(4)}, Lng: ${tempLng!.toStringAsFixed(4)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                     ),

                  const SizedBox(height: 12),
                  TextField(controller: subdomainCtrl, decoration: const InputDecoration(labelText: 'Subdominio', prefixText: 'plads.app/')),
                   
                   const SizedBox(height: 24),
                   const Text('Redes Sociales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                   TextField(
                     controller: instaCtrl, 
                     decoration: const InputDecoration(labelText: 'Instagram', prefixIcon: Icon(Icons.camera_alt, size: 16), hintText: '@usuario')
                   ),
                   TextField(
                     controller: fbCtrl, 
                     decoration: const InputDecoration(labelText: 'Facebook', prefixIcon: Icon(Icons.facebook, size: 16), hintText: 'PaginaFB')
                   ),
                   TextField(
                     controller: webCtrl, 
                     decoration: const InputDecoration(labelText: 'Sitio Web', prefixIcon: Icon(Icons.language, size: 16), hintText: 'www.miweb.cl')
                   ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                   final Map<String, String> newLinks = {};
                   if (instaCtrl.text.isNotEmpty) newLinks['instagram'] = instaCtrl.text;
                   if (fbCtrl.text.isNotEmpty) newLinks['facebook'] = fbCtrl.text;
                   if (webCtrl.text.isNotEmpty) newLinks['website'] = webCtrl.text;

                   final service = Provider.of<AcademyService>(context, listen: false);
                   await service.updateAcademyInfo(
                     academyId: academy.id,
                     name: nameCtrl.text,
                     address: addressCtrl.text,
                     region: selectedRegion,
                     commune: selectedCommune,
                     subdomain: subdomainCtrl.text,
                     socialLinks: newLinks,
                     latitude: tempLat,
                     longitude: tempLng,
                   );
                   if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar'),
              )
            ],
          );
        }
      ),
    );
  }
}


class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  
  const _StatItem({required this.label, required this.value, required this.change});

  @override
  Widget build(BuildContext context) {
    // Basic implementation for stats
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(change, style: const TextStyle(
          color: Colors.grey, 
          fontSize: 12, 
          fontWeight: FontWeight.bold
        )),
      ],
    );
  }
}
