import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/class_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/academy_service.dart';
import '../../../../models/venue_model.dart';
import '../../../../models/room_model.dart'; // Import RoomModel
import '../../../../models/user_model.dart'; // Import UserModel
import 'package:firebase_auth/firebase_auth.dart'; // Import User if needed, or rely on Custom User Model
import 'package:intl/intl.dart';
import '../../../../models/class_type_model.dart';
import 'manage_class_types_screen.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io'; // Import File
import '../../../../services/storage_service.dart'; // Import Storage Service
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../common/map_picker_screen.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../utils/location_helper.dart';

class CreateClassScreen extends StatefulWidget {
  final DateTime? initialDate;

  const CreateClassScreen({super.key, this.initialDate});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class ScheduleItem {
  String day;
  TimeOfDay time;
  ScheduleItem({required this.day, required this.time});
}

class PricingPlan {
  String type;
  String title;
  String description;
  String price;
  int credits;
  
  PricingPlan({required this.type, required this.title, required this.description, required this.price, required this.credits});
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  int _currentStep = 0;
  
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _capacityController = TextEditingController(text: '20'); // Default capacity
  
  ClassType? _selectedType; // Selected Class Type
  String _classType = 'Clase'; 
  String _selectedCategory = 'Baile';
  String _selectedSubcategory = 'Bachata';
  String _selectedLevel = 'Básico';
  

  
  // Image State
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  final List<ScheduleItem> _schedules = [
    ScheduleItem(day: 'Lunes', time: const TimeOfDay(hour: 19, minute: 0))
  ];
  
  bool _isRecurring = true;
  final List<PricingPlan> _plans = [];

  // Data Lists
  final List<String> _categories = ['Baile', 'Fitness', 'Salud', 'Arte'];
  final Map<String, IconData> _categoryIcons = {
    'Baile': Icons.music_note,
    'Fitness': Icons.fitness_center,
    'Salud': Icons.favorite,
    'Arte': Icons.palette,
  };
  
  final Map<String, List<String>> _subcategories = {
    'Baile': [
      'Salsa', 'Bachata', 'Kizomba', 'Reggaeton', 'Urbano', 'Ballet', 'Jazz', 
      'Ballroom', 'Flamenco', 'Tango', 'Danza Árabe', 'Cueca', 'Folclore', 'Acro danza'
    ],
    'Fitness': [
      'Calistenia', 'Crossfit', 'Funcional', 'Yoga', 'Pilates', 'OCR', 'TRX', 'Acrobacia',
      'Karate', 'Kickboxing', 'Muay Thai', 'Boxeo', 'Tae kwon Do', 'Jujitsu', 'Capoeira'
    ],
    'Salud': ['Masoterapia', 'Nutrición', 'Meditación', 'Kinesiología', 'Acupuntura'],
    'Arte': ['Pintura', 'Teatro', 'Fotografía'],
  };

  final List<String> _levels = ['Básico', 'Intermedio', 'Avanzado', 'Multinivel'];
  final List<String> _days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  // Advanced Location Data (Simplified for MVP)
  final List<String> _regions = ['Metropolitana', 'Valparaíso', 'Biobío', 'O\'Higgins', 'Maule'];
  final Map<String, List<String>> _comunasByRegion = {
    'Metropolitana': ['Providencia', 'Las Condes', 'Santiago', 'Ñuñoa', 'La Florida', 'Vitacura', 'La Reina', 'Peñalolén', 'Macul', 'Maipú'],
    'Valparaíso': ['Viña del Mar', 'Valparaíso', 'Concón', 'Quilpué'],
    'Biobío': ['Concepción', 'Talcahuano', 'San Pedro'],
    'O\'Higgins': ['Rancagua', 'Machalí'],
    'Maule': ['Talca', 'Curicó'],
  };

  String _selectedRegion = 'Metropolitana';
  String _selectedComuna = 'Providencia';

  bool _isLoading = false;

  // Location State
  double? _selectedLat;
  double? _selectedLng;

  String get _eventLabel => _selectedCategory == 'Salud' ? 'Sesión' : 'Clase';

  @override
  void initState() {
    super.initState();
    
    // Pre-fill schedule if a date was passed from Calendar
    if (widget.initialDate != null) {
      final weekdayIndex = widget.initialDate!.weekday - 1; // 1 (Mon) -> 0
      if (weekdayIndex >= 0 && weekdayIndex < _days.length) {
        _schedules[0].day = _days[weekdayIndex];
      }
    }

    // Pre-load academy data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
          Provider.of<AcademyService>(context, listen: false).loadAcademy(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = Provider.of<FirestoreService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Crear Nueva $_eventLabel'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD000FF)),
          ),
          
          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              elevation: 0,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(child: OutlinedButton(onPressed: details.onStepCancel, child: const Text('Atrás'))),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD000FF),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_currentStep == 3 ? 'Publicar $_eventLabel' : 'Siguiente'),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onStepContinue: () async {
                if (_isLoading) return; // Prevent double submission

                bool isValid = false;

                if (_currentStep == 0) {
                  if (_formKeyStep1.currentState!.validate()) isValid = true;
                } else if (_currentStep == 1) {
                  if (_formKeyStep2.currentState!.validate()) {
                    if (_schedules.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes agregar al menos un horario'), backgroundColor: Colors.red));
                       return;
                    }
                    isValid = true;
                  }
                } else if (_currentStep == 2) {
                  if (_formKeyStep3.currentState!.validate()) isValid = true;
                } else {
                  // Step 3 (Confirmation) - Save to Firestore
                  isValid = true;
                }

                if (isValid) {
                  if (_currentStep < 3) {
                    setState(() => _currentStep += 1);
                  } else {
                     // FINAL SAVE LOGIC
                     setState(() => _isLoading = true);
                     
                     // 1. Automatic Geocoding if missing
                     if (_selectedLat == null && _addressController.text.isNotEmpty) {
                        String query = '';
                        try {
                           query = '${_addressController.text}, ${_selectedComuna}, ${_selectedRegion}, Chile';
                           List<Location> locations = await locationFromAddress(query);
                           if (locations.isNotEmpty) {
                             _selectedLat = locations.first.latitude;
                             _selectedLng = locations.first.longitude;
                             print("✅ Geocoding successful: $_selectedLat, $_selectedLng");
                           }
                        } catch (e) {
                           print("⚠️ Geocoding failed for '$query': $e");
                           // We continue even if it fails.
                        }
                     }

                     try {
                        // Get current User ID synchronously to avoid stream hang
                        final user = authService.currentUser; 
                        if (user == null) throw Exception('Usuario no autenticado');
                        final String userId = user.uid;

                         // Construct Date & Time
                        final now = DateTime.now();
                        final baseDate = widget.initialDate ?? now.add(const Duration(days: 1));
                        
                        // Determine number of weeks to generate (1 month if recurring)
                        int weeksToGenerate = _isRecurring ? 4 : 1; 

                        // 2. Upload Image if selected
                        String? imageUrl;
                        if (_selectedImage != null) {
                          final storageService = StorageService();
                          imageUrl = await storageService.uploadImage(
                            image: _selectedImage!, 
                            folder: 'class_images/$userId'
                          );
                        } 

                        for (int w = 0; w < weeksToGenerate; w++) {
                          for (var schedule in _schedules) {
                             // Calculate date for this schedule in the current week offset
                             final weekOffsetDate = baseDate.add(Duration(days: w * 7));
                             DateTime targetDate = weekOffsetDate;
                             
                             int currentWeekday = weekOffsetDate.weekday; // Mon=1...Sun=7
                             int targetWeekday = _days.indexOf(schedule.day) + 1; // Mon=1
                             int daysToAdd = (targetWeekday - currentWeekday + 7) % 7;
                             
                             if (daysToAdd == 0 && w == 0 && weekOffsetDate.isAfter(DateTime(weekOffsetDate.year, weekOffsetDate.month, weekOffsetDate.day, schedule.time.hour, schedule.time.minute))) {
                                // If today is the day but time passed, add 7 days (next week)
                                daysToAdd = 7;
                             }
                             
                             targetDate = weekOffsetDate.add(Duration(days: daysToAdd));
                             
                             final hour = schedule.time.hour;
                             final minute = schedule.time.minute;
                             
                             final classDate = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);

                             print('DEBUG: Creating class for $classDate (Week $w)'); // DEBUG LOG

                             final newClass = ClassModel(
                               id: '', 
                               instructorId: userId,
                               title: _titleController.text,
                               description: _descriptionController.text,
                               date: classDate,
                               startTime: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                               endTime: '${(hour + 1).toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                               capacity: int.tryParse(_capacityController.text) ?? 20, 
                               price: double.tryParse(_basePriceController.text) ?? 5000,
                               location: _addressController.text,
                               latitude: _selectedLat, // Add lat
                               longitude: _selectedLng, // Add lng
                               attendeeIds: [],
                               classTypeId: _selectedType?.id,
                               category: _selectedCategory, // Use the UI state, not just the type
                               discipline: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : (_selectedType?.discipline ?? _titleController.text), 
                               targetAudience: _selectedType?.targetAudience ?? _selectedLevel, // Or add a field for audience if manual
                               region: _selectedRegion, 
                               comuna: _selectedComuna, 
                               color: _selectedType?.color ?? '#39FF14',
                               imageUrl: imageUrl, // Save Image URL
                               availablePlans: _plans.map((p) => {
                                 'title': p.title,
                                 'description': p.description,
                                 'price': double.tryParse(p.price) ?? 0,
                                 'credits': p.credits,
                                 'type': p.type,
                               }).toList(),
                             );

                             await firestoreService.createClass(newClass);
                          }
                        }

                         if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 ¡${_isRecurring ? "Clases recurrentes" : "Clase"} creada${_isRecurring ? "s" : ""} con éxito!')));
                            Navigator.pop(context); 
                         }
                     } catch (e) {
                        setState(() => _isLoading = false);
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                     }
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                   setState(() => _currentStep -= 1);
                }
              },
              steps: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
                _buildStep4(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep1(ThemeData theme) {
    // Sort subcategories alphabetically
    _subcategories['Baile']!.sort();
    
    return Step(
      title: const Text(''),
      label: const Text('Concepto'),
      state: _currentStep > 0 ? StepState.complete : StepState.editing,
      isActive: _currentStep >= 0,
      content: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // --- IMAGE PICKER ---
             Center(
               child: GestureDetector(
                 onTap: _pickImage,
                 child: Container(
                   height: 180,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                     borderRadius: BorderRadius.circular(16),
                     image: _selectedImage != null 
                        ? DecorationImage(
                            image: FileImage(File(_selectedImage!.path)), 
                            fit: BoxFit.cover
                          )
                        : null,
                     border: Border.all(color: Colors.grey.withOpacity(0.3)),
                   ),
                   child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: theme.primaryColor),
                            const SizedBox(height: 8),
                            Text('Agregar Foto de Portada', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                            const Text('(Opcional)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                onPressed: _removeImage,
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                child: const Text('Cambiar', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            )
                          ],
                        ),
                 ),
               ),
             ),
             const SizedBox(height: 20),

             // --- CLASS TYPE SELECTOR ---
             StreamBuilder<UserModel?>(
               stream: Provider.of<AuthService>(context, listen: false).user,
               builder: (context, userSnapshot) {
                 final user = userSnapshot.data;
                 return StreamBuilder<List<ClassType>>(
                   stream: user != null 
                      ? Provider.of<FirestoreService>(context).getClassTypes(user.id) 
                      : Stream.value(<ClassType>[]),
                   builder: (context, snapshot) {
                     final types = snapshot.data ?? [];
                 
                     return Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             const Text('Tipo de Clase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                             TextButton.icon(
                               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageClassTypesScreen())),
                               icon: const Icon(Icons.edit_note, size: 18),
                               label: const Text('Gestionar Tipos')
                             )
                           ],
                         ),
                         const SizedBox(height: 8),
                         if (types.isEmpty)
                           Container(
                             padding: const EdgeInsets.all(16),
                             width: double.infinity,
                             decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                             child: Column(
                               children: [
                                 const Text(
                                   '¿No encuentras tu estilo?', 
                                   style: TextStyle(fontWeight: FontWeight.bold),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: 4),
                                 const Text(
                                   'Créalo aquí para que sea verificado y agregado a tu perfil.',
                                   textAlign: TextAlign.center,
                                   style: TextStyle(fontSize: 12, color: Colors.grey),
                                 ),
                                 const SizedBox(height: 8),
                                 TextButton(
                                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageClassTypesScreen())),
                                   child: const Text('Crear nuevo tipo (Ej: Salsa)')
                                 )
                               ],
                             ),
                           )
                         else
                           DropdownButtonFormField<String>(
                             value: _selectedType?.id,
                             decoration: InputDecoration(
                               labelText: 'Selecciona una actividad',
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                               prefixIcon: _selectedType != null 
                                  ? Icon(Icons.circle, color: Color((int.tryParse(_selectedType!.color.replaceAll('#', ''), radix: 16) ?? 0xFF00FF00) + 0xFF000000))
                                  : const Icon(Icons.category),
                             ),
                             items: types.map((t) => DropdownMenuItem(
                               value: t.id, 
                               child: Text(t.name)
                             )).toList(),
                             onChanged: (val) {
                                final type = types.firstWhere((t) => t.id == val);
                                setState(() {
                                  _selectedType = type;
                                  _titleController.text = type.name;
                                  _basePriceController.text = type.defaultPrice.toInt().toString();
                                  _capacityController.text = type.defaultCapacity.toString();
                                  _selectedCategory = type.category;
                                  if (_subcategories.containsKey(type.category)) {
                                    _selectedSubcategory = _subcategories[type.category]!.first;
                                  }
                                });
                             },
                           ),
                       ],
                     );
                   }
                 );
               }
             ),
             const SizedBox(height: 20),
             
             // Fallback / Customization Fields
             DropdownButtonFormField<String>(
               value: _classType,
               decoration: InputDecoration(
                 labelText: 'Formato',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                 prefixIcon: const Icon(Icons.label),
               ),
               items: ['Clase', 'Coach', 'Bootcamp'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
               onChanged: (val) => setState(() => _classType = val!),
             ),
             const SizedBox(height: 20),
             
             // Dynamic Category Icons - Allow manual override
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      // Update subcategory to default of new category to avoid mismatch
                      if (_subcategories.containsKey(cat)) {
                        _selectedSubcategory = _subcategories[cat]!.first;
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD000FF) : (theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: const Color(0xFFD000FF), width: 2) : null,
                        ),
                        child: Icon(_categoryIcons[cat], color: isSelected ? Colors.white : Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(cat, style: TextStyle(
                        fontSize: 12, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFD000FF) : null,
                      )),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es obligatorio' : null,
              decoration: InputDecoration(
                labelText: 'Nombre de la actividad *',
                hintText: 'Ej: Bachata Sensual Principiantes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
             const SizedBox(height: 16),

             TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción (Opcional)',
                hintText: '¿De qué trata la clase? ¿Qué aprenderán?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
             const SizedBox(height: 20),
             
             DropdownButtonFormField<String>(
               value: _selectedSubcategory,
               isExpanded: true,
               decoration: InputDecoration(
                 labelText: 'Subcategoría',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
               ),
               items: _subcategories[_selectedCategory]!.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
               onChanged: (val) => setState(() => _selectedSubcategory = val!),
             ),
             
             const SizedBox(height: 20),
             
             const Text('Nivel', style: TextStyle(fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Wrap(
               spacing: 8,
               children: _levels.map((lvl) {
                 final isSelected = _selectedLevel == lvl;
                 return ChoiceChip(
                   label: Text(lvl),
                   selected: isSelected,
                   selectedColor: const Color(0xFF39FF14).withOpacity(0.2),
                   labelStyle: TextStyle(color: isSelected ? const Color(0xFF39FF14) : Colors.grey),
                   checkmarkColor: const Color(0xFF00AA00),
                   onSelected: (val) => setState(() => _selectedLevel = lvl),
                 );
               }).toList(),
             ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2(ThemeData theme) {
    // Get Academy Data
    final academyService = Provider.of<AcademyService>(context);
    final academy = academyService.currentAcademy;
    final rooms = academy?.rooms ?? [];

    return Step(
      title: const Text(''),
      label: const Text('Logística'),
      state: _currentStep > 1 ? StepState.complete : StepState.editing,
      isActive: _currentStep >= 1,
      content: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // --- SAVED VENUES SELECTOR (ACADEMY + PERSONAL) ---
             // --- SAVED VENUES SELECTOR (ACADEMY + PERSONAL) ---
             Builder(
               builder: (context) {
                 final authService = Provider.of<AuthService>(context, listen: false);
                 final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                 final currentUser = authService.currentUser;
                 
                 return StreamBuilder<List<VenueModel>>(
                   stream: currentUser != null 
                       ? firestoreService.getUserVenues(currentUser.uid) 
                       : Stream.value([]),
                   builder: (context, snapshot) {
                 final userVenues = snapshot.data ?? [];
                 final allOptions = [
                   ...rooms.map((r) => {'id': 'room_${r.id}', 'name': r.name, 'type': 'room', 'obj': r}),
                   ...userVenues.map((v) => {'id': 'venue_${v.id}', 'name': v.name, 'type': 'venue', 'obj': v}),
                 ];

                 if (allOptions.isEmpty) return const SizedBox.shrink();

                 return Column(
                   children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.neonPurple.withOpacity(0.3))
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                 Icon(Icons.place, color: AppColors.neonPurple, size: 16),
                                 const SizedBox(width: 8),
                                 const Text('Tus Sedes Guardadas', style: TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Seleccionar Sede / Sala',
                                prefixIcon: const Icon(Icons.store),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: true,
                                fillColor: Theme.of(context).cardTheme.color,
                              ),
                              items: allOptions.map((opt) {
                                final isRoom = opt['type'] == 'room';
                                final suffix = isRoom ? ' (Academia)' : ' (Personal)';
                                return DropdownMenuItem(
                                  value: opt['id'] as String,
                                  child: Text('${opt['name']}$suffix', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                 final selected = allOptions.firstWhere((o) => o['id'] == val);
                                 setState(() {
                                   if (selected['type'] == 'room') {
                                      // Academy Room
                                      if (academy != null) {
                                         _selectedRegion = _comunasByRegion.containsKey(academy.region) ? academy.region : _comunasByRegion.keys.first;
                                         _selectedComuna = academy.commune; 
                                          if (!(_comunasByRegion[_selectedRegion]?.contains(_selectedComuna) ?? false)) {
                                             _selectedComuna = _comunasByRegion[_selectedRegion]?.first ?? 'Providencia';
                                          }
                                         _addressController.text = academy.address;
                                         _selectedLat = academy.latitude;
                                         _selectedLng = academy.longitude;
                                      }
                                      final r = selected['obj'] as RoomModel;
                                      _capacityController.text = r.capacity.toString();
                                   } else {
                                      // Personal Venue
                                      final v = selected['obj'] as VenueModel;
                                      
                                      if (_comunasByRegion.containsKey(v.region)) {
                                         _selectedRegion = v.region;
                                      }
                                      
                                      if (_comunasByRegion[_selectedRegion]?.contains(v.commune) ?? false) {
                                         _selectedComuna = v.commune;
                                      } else {
                                         _selectedComuna = _comunasByRegion[_selectedRegion]?.first ?? 'Providencia';
                                      }

                                      _addressController.text = v.address; 
                                      _selectedLat = v.latitude;
                                      _selectedLng = v.longitude;
                                   }
                                 });
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                   content: Text('✅ Ubicación seleccionada.'),
                                   duration: Duration(seconds: 1),
                                   backgroundColor: AppColors.neonGreen,
                                 ));
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("O ingresa manualmente", style: TextStyle(color: Colors.grey, fontSize: 12))), Expanded(child: Divider())]),
                      const SizedBox(height: 16),
                   ],
                 );
               }
             ); // Close StreamBuilder
               }
             ), // Close Builder
             
             // === REGION & COMUNA SELECTOR ===
             const Align(alignment: Alignment.centerLeft, child: Text("Define la Zona (Para filtros)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
             const SizedBox(height: 8),
             Row(
               children: [
                 Expanded(
                   child: DropdownButtonFormField<String>(
                     value: _selectedRegion,
                     decoration: const InputDecoration(labelText: 'Región', border: OutlineInputBorder()),
                     items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                     onChanged: (val) {
                       setState(() {
                         _selectedRegion = val!;
                         _selectedComuna = _comunasByRegion[val]!.first;
                       });
                     },
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: DropdownButtonFormField<String>(
                     value: _selectedComuna,
                     decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
                     items: _comunasByRegion[_selectedRegion]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                     onChanged: (val) => setState(() => _selectedComuna = val!),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 16),
             // =================================
             
             Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => value == null || value.trim().isEmpty ? 'La dirección es obligatoria' : null,
                      decoration: InputDecoration(
                        labelText: 'Dirección / Sede *',
                        prefixIcon: const Icon(Icons.location_on),
                        hintText: 'Ej: Av. Providencia 1234, Estudio A',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                   Container( // Map Button
                     margin: const EdgeInsets.only(top: 4),
                     decoration: BoxDecoration(
                       color: _selectedLat != null ? AppColors.neonGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: _selectedLat != null ? AppColors.neonGreen : Colors.grey.withOpacity(0.3))
                     ),
                     child: IconButton(
                       icon: Icon(Icons.map, color: _selectedLat != null ? AppColors.neonGreen : Colors.grey),
                       tooltip: 'Ubicación en Mapa',
                       onPressed: () async {
                           final result = await Navigator.push(
                             context, 
                             MaterialPageRoute(builder: (_) => MapPickerScreen(
                               initialPosition: (_selectedLat != null && _selectedLng != null)
                                ? LatLng(_selectedLat!, _selectedLng!)
                                : const LatLng(-33.4489, -70.6693)
                             )) 
                           );
                           
                           if (result != null && result is Map) {
                              final latLng = result['latLng'] as LatLng;
                              final address = result['address'] as String?;
                              final commune = result['commune'] as String?;
                              final region = result['region'] as String?;

                              setState(() {
                                _selectedLat = latLng.latitude;
                                _selectedLng = latLng.longitude;
                                
                                if (address != null && address.isNotEmpty) {
                                  _addressController.text = address;
                                }
                                
                                 // Use LocationHelper for matching
                                 final matchedRegion = LocationHelper.matchRegion(region);
                                 if (matchedRegion != null) {
                                   _selectedRegion = matchedRegion;
                                   
                                   // Update commune list based on matched region
                                   if (_comunasByRegion.containsKey(matchedRegion)) {
                                      final matchedCommune = LocationHelper.matchCommune(matchedRegion, commune);
                                      if (matchedCommune != null) {
                                        _selectedComuna = matchedCommune;
                                      } else {
                                        // Default to first if specific commune logic fails but region is new
                                        _selectedComuna = _comunasByRegion[matchedRegion]!.first;
                                      }
                                   }
                                 }
                              });
                           }
                       },
                     ),
                   )
                ],
             ),
             if (_selectedLat != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 4, left: 4),
                   child: Text('📍 Coordenadas: ${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11, color: AppColors.neonGreen)),
                 ),

            const SizedBox(height: 16),
            
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
              decoration: InputDecoration(
                labelText: 'Cantidad de Cupos (Aforo)',
                prefixIcon: const Icon(Icons.people),
                hintText: 'Ej: 20',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text('Horarios *', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
  
            // Dynamic Schedule List
            if (_schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Agrega al menos un horario', style: TextStyle(color: Colors.red)),
              ),
              
            ..._schedules.asMap().entries.map((entry) {
              int index = entry.key;
              ScheduleItem item = entry.value;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                color: theme.cardTheme.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: item.day,
                          decoration: const InputDecoration(labelText: 'Día', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                          items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (val) => setState(() => item.day = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: item.time);
                            if (t != null) setState(() => item.time = t);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Hora', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                            child: Text(item.time.format(context)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                           setState(() => _schedules.removeAt(index));
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            TextButton.icon(
              onPressed: () => setState(() => _schedules.add(ScheduleItem(day: 'Lunes', time: const TimeOfDay(hour: 19, minute: 0)))),
              icon: const Icon(Icons.add_circle, color: Color(0xFFD000FF)),
              label: const Text('Agregar otro horario', style: TextStyle(color: Color(0xFFD000FF))),
            ),
  
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Repetir semanalmente'),
              subtitle: const Text('Los horarios se agendarán automáticamente'),
              value: _isRecurring,
              activeColor: const Color(0xFF39FF14),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _isRecurring = val),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep3(ThemeData theme) {
    return Step(
      title: const Text(''),
      label: const Text('Precios'),
      state: _currentStep > 2 ? StepState.complete : StepState.editing,
      isActive: _currentStep >= 2,
      content: Form(
        key: _formKeyStep3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             TextFormField(
              controller: _basePriceController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Requerido';
                if (double.tryParse(value) == null) return 'Ingresa un número válido';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Valor Clase Suelta (CLP) *',
                prefixIcon: const Icon(Icons.attach_money),
                hintText: 'Ej: 10000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Planes y Promociones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(onPressed: () => _showAddPlanModal(context), icon: const Icon(Icons.add_circle, color: Color(0xFFD000FF), size: 30)),
              ],
            ),
            const SizedBox(height: 10),
            
            if (_plans.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: const Column(
                  children: [
                    Icon(Icons.local_offer, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text('No has agregado planes', style: TextStyle(color: Colors.grey)),
                    Text('Crea packs (ej: 4 clases) o planes mensuales', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),

             ..._plans.map((p) => Card(
               margin: const EdgeInsets.only(bottom: 8),
               child: ListTile(
                 leading: const Icon(Icons.card_membership, color: Colors.purple),
                 title: Text(p.title),
                 subtitle: Text(p.description),
                 trailing: Text('\$${p.price}', style: const TextStyle(fontWeight: FontWeight.bold)),
               ),
             )),
          ],
        ),
      ),
    );
  }
  
  Step _buildStep4(ThemeData theme) {
     return Step(
       title: const Text(''),
       label: const Text('Publicar'),
       state: _currentStep == 3 ? StepState.complete : StepState.editing,
       isActive: _currentStep >= 3,
       content: Column(
         children: [
           const Icon(Icons.check_circle, color: Color(0xFF39FF14), size: 64),
           const SizedBox(height: 16),
           const Text('¡Todo Listo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           const Text('Revisa los detalles antes de publicar tu clase.', style: TextStyle(color: Colors.grey)),
           const SizedBox(height: 24),
           _buildSummaryRow('Actividad', _titleController.text),
           _buildSummaryRow('Tipo', '$_classType - $_selectedCategory'),
           _buildSummaryRow('Horario', _schedules.map((s) => '${s.day} ${s.time.format(context)}').join(', ')),
           _buildSummaryRow('Lugar', _addressController.text), // Shows auto-filled address
           _buildSummaryRow('Cupos', _capacityController.text),
           _buildSummaryRow('Precio Base', '\$${_basePriceController.text}'),
         ],
       ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }



// ... existing code ...

  void _showAddPlanModal(BuildContext context) {
    String pType = 'pack';
    final pTitleCtrl = TextEditingController();
    final pDescCtrl = TextEditingController();
    final pPriceCtrl = TextEditingController();
    final pCreditsCtrl = TextEditingController(text: '4'); // Default 4

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo Plan de Precios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: pType,
              items: const [
                DropdownMenuItem(value: 'pack', child: Text('Pack de Clases')),
                DropdownMenuItem(value: 'monthly', child: Text('Mensualidad')),
              ],
              onChanged: (val) => pType = val!,
              decoration: const InputDecoration(labelText: 'Tipo de Plan', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(controller: pTitleCtrl, decoration: const InputDecoration(labelText: 'Nombre (Ej: Pack 8 Clases)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
             TextField(controller: pCreditsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad de Clases (Créditos)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: pDescCtrl, decoration: const InputDecoration(labelText: 'Descripción (Ej: Válido 2 meses)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: pPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Total', prefixText: '\$ ', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD000FF), foregroundColor: Colors.white),
                onPressed: () {
                  if (pTitleCtrl.text.isNotEmpty && pPriceCtrl.text.isNotEmpty) {
                    setState(() {
                      _plans.add(PricingPlan(
                        type: pType, 
                        title: pTitleCtrl.text, 
                        description: pDescCtrl.text, 
                        price: pPriceCtrl.text,
                        credits: int.tryParse(pCreditsCtrl.text) ?? 1
                      ));
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Agregar Plan'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
