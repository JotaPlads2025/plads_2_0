import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/auth_service.dart'; // Import AuthService
import '../../../../models/venue_model.dart';
import '../../../../models/user_model.dart'; // Import UserModel
import '../../../../widgets/neon_widgets.dart';
import '../../../../data/mock_repository.dart';
import '../finance/finance_screen.dart';
import 'package:plads_2_0/main.dart'; // Import for themeNotifier
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/subscription_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import '../../common/map_picker_screen.dart'; 
import 'package:geocoding/geocoding.dart';
import '../../../../utils/location_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- State: Notifications ---
  bool newBookingsEnabled = true;
  String newBookingsFreq = 'immediate'; 

  bool classRemindersEnabled = true;
  String classRemindersTime = '24'; 

  bool cancellationsEnabled = false;
  String cancellationsFreq = 'immediate'; 

  bool weeklySummaryEnabled = true;

  // --- Mock Data: Regions & Communes (Chile) ---
  final Map<String, List<String>> _communesByRegion = {
    'Metropolitana': ['Santiago', 'Providencia', 'Las Condes', 'Ñuñoa', 'La Florida', 'Maipú', 'Vitacura', 'La Reina', 'Peñalolén', 'Macul', 'San Miguel', 'Estación Central', 'Recoleta', 'Huechuraba', 'Pudahuel', 'Quilicura'],
    'Valparaíso': ['Valparaíso', 'Viña del Mar', 'Concón', 'Quilpué', 'Villa Alemana'],
    'Biobío': ['Concepción', 'Talcahuano', 'San Pedro de la Paz', 'Chiguayante'],
    'O\'Higgins': ['Rancagua', 'Machalí'],
    'Maule': ['Talca', 'Curicó'],
  };
  late String _selectedRegion;
  String? _selectedCommune;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _selectedRegion = _communesByRegion.keys.first;
    _selectedCommune = _communesByRegion[_selectedRegion]!.first;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      newBookingsEnabled = prefs.getBool('pref_newBookings') ?? true;
      newBookingsFreq = prefs.getString('pref_newBookingsFreq') ?? 'immediate';
      
      classRemindersEnabled = prefs.getBool('pref_classReminders') ?? true;
      classRemindersTime = prefs.getString('pref_classRemindersTime') ?? '24';
      
      cancellationsEnabled = prefs.getBool('pref_cancellations') ?? false;
      cancellationsFreq = prefs.getString('pref_cancellationsFreq') ?? 'immediate';
      
      weeklySummaryEnabled = prefs.getBool('pref_weeklySummary') ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // final venues = MockRepository().venues; // Removed mock

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Configuraciones'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Plan Card
            _buildPlanCard(theme),
            const SizedBox(height: 24),

            // 2. Venues Management
            _buildVenuesCard(theme), 
            const SizedBox(height: 24),

            // 3. APARIENCIA (New)
            _buildAppearanceCard(theme),
            const SizedBox(height: 24),

            // 4. Notifications Settings
            _buildNotificationsCard(theme),
            const SizedBox(height: 24),

            // 5. Account Actions
            _buildAccountCard(theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 1. Plan Widgets ---
  Widget _buildPlanCard(ThemeData theme) {
    final authService = Provider.of<AuthService>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final userPlanId = authService.currentUserModel?.planType ?? 'commission';
    final plan = subscriptionService.getPlan(userPlanId);

    // Dynamic Text Logic
    String statusMsg = '';
    String buttonText = 'Ver Planes';
    
    if (userPlanId == 'commission') {
      statusMsg = 'Actualmente estás en el plan Comisión. Mejora a Basic o Pro para reducir comisiones y obtener verificación.';
      buttonText = 'Mejorar Plan';
    } else if (userPlanId == 'basic') {
      statusMsg = 'Tienes el Plan Básico. ¡Excelente! Consigue IA y Academia migrando a Pro.';
      buttonText = 'Mejorar a Pro';
    } else if (userPlanId == 'pro') {
      statusMsg = '¡Eres un usuario Pro! Estás en la cima. Disfruta de la menor comisión y todas las herramientas.';
      buttonText = 'Ver Detalles';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        gradient: LinearGradient(
              colors: [
                userPlanId == 'pro' ? AppColors.neonGreen.withOpacity(0.2) : Colors.deepPurple.shade900.withOpacity(0.5),
                theme.cardTheme.color ?? Colors.transparent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rocket_launch, color: userPlanId == 'pro' ? AppColors.neonGreen : AppColors.neonPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  plan.name, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: userPlanId == 'pro' ? AppColors.neonGreen : null
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
           Text(
            statusMsg,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: NeonButton(
              text: buttonText, 
              color: userPlanId == 'pro' ? Colors.grey : AppColors.neonGreen, 
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen()));
              }
            ),
          )
        ],
      ),
    );
  }

  // --- 2. Venues Widgets ---
  Widget _buildVenuesCard(ThemeData theme) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false); 
    // We need the user ID. Assuming access via AuthService or similar, 
    // but better to wrap this widget in a Consumer of AuthService if not available.
    // However, SettingsScreen does not inject AuthService at top level build easily without modifying build.
    // I will use Provider.of<AuthService> inside the stream builder or pass it.
    
    // Actually, let's just get the user ID here.
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final userId = currentUser?.uid;

    if (userId == null) return const SizedBox.shrink(); // Or show login prompt

    return StreamBuilder<List<VenueModel>>(
      stream: firestoreService.getUserVenues(userId),
      builder: (context, snapshot) {
            final venues = snapshot.data ?? [];

            return Container(
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
                    children: [
                      const Text('Mis Sedes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.neonPurple),
                        onPressed: () => _showAddVenueSheet(context, userId),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Administra las ubicaciones frecuentes.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  if (venues.isEmpty)
                     const Center(child: Padding(
                       padding: EdgeInsets.all(16.0),
                       child: Text('No has añadido ninguna sede.', style: TextStyle(color: Colors.grey)),
                     ))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: venues.length,
                      separatorBuilder: (_,__) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final venue = venues[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.place, color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${venue.address}, ${venue.commune}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () {
                                   firestoreService.deleteUserVenue(userId, venue.id);
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sede eliminada')));
                                }, 
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    
                   const SizedBox(height: 12),
                   SizedBox(
                     width: double.infinity,
                     child: OutlinedButton.icon(
                       onPressed: () => _showAddVenueSheet(context, userId),
                       icon: const Icon(Icons.add),
                       label: const Text('Añadir nueva sede'),
                       style: OutlinedButton.styleFrom(
                         foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                         side: BorderSide(color: Colors.grey.shade600)
                       )
                     ),
                   )
                ],
              ),
            );
      }
    );
  }

  // --- 3. Appearance Widgets ---
  Widget _buildAppearanceCard(ThemeData theme) {
    return Container(
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
            children: const [
              Icon(Icons.brightness_6, color: AppColors.neonPurple),
              SizedBox(width: 12),
              Text('Apariencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Elige el tema de la aplicación.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return Row(
                children: [
                  Expanded(child: _buildThemeOption(context, 'Sistema', ThemeMode.system, currentMode, Icons.brightness_auto)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildThemeOption(context, 'Claro', ThemeMode.light, currentMode, Icons.light_mode)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildThemeOption(context, 'Oscuro', ThemeMode.dark, currentMode, Icons.dark_mode)),
                ],
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, ThemeMode mode, ThemeMode currentMode, IconData icon) {
    final isSelected = mode == currentMode;
    final theme = Theme.of(context);
    // Determine colors based on selection and current theme
    final bgColor = isSelected ? AppColors.neonPurple.withOpacity(0.1) : theme.scaffoldBackgroundColor;
    final borderColor = isSelected ? AppColors.neonPurple : Colors.grey.withOpacity(0.3);
    final contentColor = isSelected ? AppColors.neonPurple : Colors.grey;
    
    // ... (inside the _buildThemeOption method)

    return GestureDetector(
      onTap: () async {
        themeNotifier.value = mode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('themeMode', mode.toString());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: contentColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 12, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: contentColor
            )),
          ],
        ),
      ),
    );
  }

  // --- 4. Notifications Widgets ---
  Widget _buildNotificationsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Controla cuándo y cómo te contactamos.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          
          _buildNotificationSwitch(
            title: 'Nuevo Agendamiento',
            subtitle: 'Notificar nuevos cupos agendados.',
            value: newBookingsEnabled,
            onChanged: (v) {
              setState(() => newBookingsEnabled = v);
              _saveBool('pref_newBookings', v);
            },
            extraControl: newBookingsEnabled ? _buildDropdown(['immediate', 'hourly', 'daily'], ['Inmediato', 'Cada hora', 'Diario'], newBookingsFreq, (v) {
               setState(() => newBookingsFreq = v!);
               _saveString('pref_newBookingsFreq', v!);
            }) : null
          ),
          const Divider(),
          _buildNotificationSwitch(
            title: 'Recordatorios de Clase',
            subtitle: 'Alertas previas a tus clases.',
            value: classRemindersEnabled,
            onChanged: (v) {
              setState(() => classRemindersEnabled = v);
              _saveBool('pref_classReminders', v);
            },
            extraControl: classRemindersEnabled ? _buildDropdown(['24', '12', '6', '1'], ['24h antes', '12h antes', '6h antes', '1h antes'], classRemindersTime, (v) {
               setState(() => classRemindersTime = v!);
               _saveString('pref_classRemindersTime', v!);
            }) : null
          ),
           const Divider(),
          _buildNotificationSwitch(
            title: 'Cancelaciones',
            subtitle: 'Notificar si un alumno cancela.',
            value: cancellationsEnabled,
            onChanged: (v) {
              setState(() => cancellationsEnabled = v);
              _saveBool('pref_cancellations', v);
            },
            extraControl: cancellationsEnabled ? _buildDropdown(['immediate', 'hourly'], ['Inmediato', 'Cada hora'], cancellationsFreq, (v) {
               setState(() => cancellationsFreq = v!);
               _saveString('pref_cancellationsFreq', v!);
            }) : null
          ),
           const Divider(),
          _buildNotificationSwitch(
            title: 'Análisis Semanal',
            subtitle: 'Resumen de métricas por correo.',
            value: weeklySummaryEnabled,
            onChanged: (v) {
              setState(() => weeklySummaryEnabled = v);
              _saveBool('pref_weeklySummary', v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? extraControl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Switch(
                value: value, 
                onChanged: onChanged,
                activeColor: AppColors.neonGreen,
              ),
            ],
          ),
          if (extraControl != null) ...[
             const SizedBox(height: 8),
             Align(alignment: Alignment.centerRight, child: extraControl),
          ]
        ],
      ),
    );
  }

  Widget _buildDropdown(List<String> values, List<String> labels, String currentValue, ValueChanged<String?> onChanged) {
    // Ensure value exists or default to first
    final safeValue = values.contains(currentValue) ? currentValue : values.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: safeValue,
        items: List.generate(values.length, (index) {
          return DropdownMenuItem(
            value: values[index],
            child: Text(labels[index], style: const TextStyle(fontSize: 12)),
          );
        }),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 16),
        isDense: true,
      ),
    );
  }

  // --- 5. Account Widgets ---
  Widget _buildAccountCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Gestión de datos y privacidad.', style: TextStyle(fontSize: 12, color: Colors.grey)),
           const SizedBox(height: 16),
           
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red.withOpacity(0.1),
                 foregroundColor: Colors.red,
                 elevation: 0,
                 side: const BorderSide(color: Colors.red),
               ),
               onPressed: () {
                 // Confirm dialog
                 showDialog(context: context, builder: (ctx) => AlertDialog(
                   title: const Text('¿Eliminar cuenta?'),
                   content: const Text('Esta acción es irreversible y perderás todos tus datos.'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                     TextButton(onPressed: () {}, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                   ],
                 ));
               }, 
               child: const Text('Eliminar Cuenta'),
             ),
           ),
           
           // --- DEV ZONE ---
           const SizedBox(height: 24),
           const Divider(),
           const SizedBox(height: 12),
           const Text('Zona de Desarrollo 🛠️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
           const SizedBox(height: 12),
           SizedBox(
             width: double.infinity,
             child: OutlinedButton.icon(
                icon: const Icon(Icons.cleaning_services, size: 18),
                label: const Text('Borrar Datos de Prueba'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                onPressed: () {
                   showDialog(context: context, builder: (ctx) => AlertDialog(
                     title: const Text('¿Borrar Datos de Prueba?'),
                     content: const Text('Esto eliminará todas tus clases, transacciones y alumnos manuales creados. Útil para reiniciar el dashboard. \n\n⚠️ Irreversible.'),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                       TextButton(onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            // Show loading snackbar
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Borrando datos...'), duration: Duration(seconds: 1)));
                            
                            final result = await Provider.of<FirestoreService>(context, listen: false).wipeUserTestData();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), duration: const Duration(seconds: 4)));
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
                          }
                       }, child: const Text('Borrar Todo', style: TextStyle(color: Colors.orange))),
                     ],
                   ));
                },
             ),
           ),
           const SizedBox(height: 12),
           SizedBox(
             width: double.infinity,
             child: OutlinedButton.icon(
                icon: const Icon(Icons.people_outline, size: 18),
                label: const Text('Reiniciar Alumnos (Borrar Listas)'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () {
                   showDialog(context: context, builder: (ctx) => AlertDialog(
                     title: const Text('¿Reiniciar Alumnos?'),
                     content: const Text('Esto eliminará todas las suscripciones, asistencias y pagos de TODOS los usuarios con rol "student". \n\nTus listas quedarán vacías.'),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                       TextButton(onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reiniciando alumnos...'), duration: Duration(seconds: 1)));
                            
                            final result = await Provider.of<FirestoreService>(context, listen: false).wipeAllStudentsData();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), duration: const Duration(seconds: 4)));
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                       }, child: const Text('Reiniciar', style: TextStyle(color: Colors.red))),
                     ],
                   ));
                },
             ),
           )
        ],
      ),
    );
  }

  // --- Helpers ---
  void _showAddVenueSheet(BuildContext context, String userId) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    
    // Reset selections
    String tempRegion = _communesByRegion.keys.first;
    String? tempCommune = _communesByRegion[tempRegion]!.first;
    
    // New: Location State
    // We need to import cloud_firestore or google_maps_flutter for LatLng or just use double variables
    // For simplicity in this file, let's use doubles or map
    double? tempLat;
    double? tempLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Añadir Nueva Sede', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre (Ej: Gimnasio FitPro)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                
                // Address + Map Button Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(labelText: 'Dirección (Ej: Av. Principal 123)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: tempLat != null ? AppColors.neonGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tempLat != null ? AppColors.neonGreen : Colors.grey.withOpacity(0.3))
                      ),
                      child: IconButton(
                        icon: Icon(Icons.map, color: tempLat != null ? AppColors.neonGreen : Colors.grey),
                         tooltip: 'Seleccionar en Mapa',
                        onPressed: () async {
                           // Import MapPickerScreen lazily or ensure it's imported at top
                           // Assuming standard route push if imported
                           // We need to import 'package:google_maps_flutter/google_maps_flutter.dart' for LatLng return type
                           // Let's rely on dynamic return for now to avoid top-level import conflict if tricky
                           
                           // Ensure MapPickerScreen returns correctly
                           final result = await Navigator.push(
                             context, 
                             MaterialPageRoute(builder: (_) => const MapPickerScreen()) 
                           );
                           
                           if (result != null && result is Map) { 
                              // Extract Data from Map
                              final latLng = result['latLng'] as LatLng;
                              final address = result['address'] as String?;
                              final region = result['region'] as String?;
                              final commune = result['commune'] as String?;

                              setSheetState(() {
                                tempLat = latLng.latitude;
                                tempLng = latLng.longitude;
                                
                                if (address != null && address.isNotEmpty) {
                                   addressCtrl.text = address;
                                }

                                // Use LocationHelper
                                final matchedRegion = LocationHelper.matchRegion(region);
                                if (matchedRegion != null && _communesByRegion.containsKey(matchedRegion)) {
                                   tempRegion = matchedRegion;
                                   
                                   final matchedCommune = LocationHelper.matchCommune(matchedRegion!, commune);
                                   if (matchedCommune != null) {
                                      tempCommune = matchedCommune;
                                   } else {
                                      tempCommune = _communesByRegion[matchedRegion]!.first;
                                   }
                                }
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📍 Ubicación guardada')));
                           }
                        },
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: tempRegion,
                        decoration: const InputDecoration(labelText: 'Región', border: OutlineInputBorder()),
                        isExpanded: true,
                        items: _communesByRegion.keys.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() {
                              tempRegion = val;
                              tempCommune = _communesByRegion[val]!.first;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: tempCommune,
                        decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
                         isExpanded: true,
                         items: _communesByRegion[tempRegion]!.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                         onChanged: (val) {
                          setSheetState(() => tempCommune = val);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white),
                    onPressed: () async {
                      if (nameCtrl.text.isNotEmpty && addressCtrl.text.isNotEmpty && tempCommune != null) {
                         final newVenue = VenueModel(
                           id: DateTime.now().millisecondsSinceEpoch.toString(),
                           name: nameCtrl.text,
                           address: addressCtrl.text,
                           region: tempRegion,
                           commune: tempCommune!,
                           latitude: tempLat,
                           longitude: tempLng,
                         );
                         
                         final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                         await firestoreService.addUserVenue(userId, newVenue);
                         
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sede guardada exitosamente')));
                      }
                    },
                    child: const Text('Guardar Sede'),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }
}
