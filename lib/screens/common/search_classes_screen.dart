import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
// import '../student/student_class_detail_screen.dart'; // TODO: Update to use new ClassModel or disable
// import '../student/profile/teacher_profile_screen.dart'; 
import 'package:provider/provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart'; // Import AuthService
import '../../../models/class_model.dart';
import 'package:intl/intl.dart';
import '../student/classes/student_class_detail_screen.dart'; // Import Detail Screen
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator

class SearchClassesScreen extends StatefulWidget {
  const SearchClassesScreen({super.key});

  @override
  State<SearchClassesScreen> createState() => _SearchClassesScreenState();
}

class _SearchClassesScreenState extends State<SearchClassesScreen> {
  bool _isMapView = false;
  String _searchTerm = '';
  
  // Filters State
  String _selectedRegion = 'Todas'; 
  String _selectedComuna = 'Todas'; // New
  String _selectedCategory = 'Todas'; 
  String _selectedAudience = 'Todas'; // New
  
  // Map State
  GoogleMapController? _mapController;
  final LatLng _defaultLocation = const LatLng(-33.4489, -70.6693); // Santiago
  LatLng? _userLocation;

  // Data Lists (Duplicated from CreateClassScreen for now - should be shared constant)
  final List<String> _regions = ['Todas', 'Metropolitana', 'Valparaíso', 'Biobío', 'O\'Higgins', 'Maule'];
  final Map<String, List<String>> _comunasByRegion = {
    'Metropolitana': ['Todas', 'Providencia', 'Las Condes', 'Santiago', 'Ñuñoa', 'La Florida', 'Vitacura', 'La Reina', 'Peñalolén', 'Macul', 'Maipú'],
    'Valparaíso': ['Todas', 'Viña del Mar', 'Valparaíso', 'Concón', 'Quilpué'],
    'Biobío': ['Todas', 'Concepción', 'Talcahuano', 'San Pedro'],
    'O\'Higgins': ['Todas', 'Rancagua', 'Machalí'],
    'Maule': ['Todas', 'Talca', 'Curicó'],
  };
  final List<String> _categories = ['Todas', 'Baile', 'Fitness', 'Salud', 'Arte', 'Otro'];
  final List<String> _audiences = ['Todas', 'Todo Público', 'Mujeres', 'Hombres', 'Niños', 'Adolescentes', 'Adulto Mayor'];
  
  Stream<List<ClassModel>>? _classesStream;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // Request location on init
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_classesStream == null) {
      _classesStream = Provider.of<FirestoreService>(context).getAllClasses();
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        
        if (_mapController != null && _isMapView) {
           _mapController!.animateCamera(
             CameraUpdate.newCameraPosition(
               CameraPosition(target: _userLocation!, zoom: 14.0)
             )
           );
        }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _classesStream = Provider.of<FirestoreService>(context, listen: false).getAllClasses();
    });
    // Small delay to show the spinner
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    // FireStoreService is now accessed in didChangeDependencies/refresh

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Clases'), 
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
               setState(() => _isMapView = !_isMapView);
               if (_isMapView && _userLocation != null && _mapController != null) {
                  // Re-center when switching to map if location is known
                   _mapController!.animateCamera(
                     CameraUpdate.newCameraPosition(
                       CameraPosition(target: _userLocation!, zoom: 14.0)
                     )
                   );
               }
            },
            tooltip: _isMapView ? 'Ver Lista' : 'Ver Mapa',
          )
        ],
      ),
      body: Column(
        children: [
          // Header & Filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            color: Theme.of(context).appBarTheme.backgroundColor, 
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar clase, instructor...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onChanged: (val) => setState(() => _searchTerm = val),
                ),
                const SizedBox(height: 12),
                // TODO: Implement real dynamic filters based on available data
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Región', _selectedRegion, _regions, (val) {
                         setState(() {
                           _selectedRegion = val!;
                           _selectedComuna = 'Todas'; // Reset Comuna when Region changes
                         });
                      }),
                      const SizedBox(width: 8),
                      // Show Comuna only if Region is selected
                      if (_selectedRegion != 'Todas') ...[
                         _buildFilterChip('Comuna', _selectedComuna, _comunasByRegion[_selectedRegion] ?? ['Todas'], (val) => setState(() => _selectedComuna = val!)),
                         const SizedBox(width: 8),
                      ],
                      _buildFilterChip('Categoría', _selectedCategory, _categories, (val) => setState(() => _selectedCategory = val!)),
                      const SizedBox(width: 8),
                      _buildFilterChip('Público', _selectedAudience, _audiences, (val) => setState(() => _selectedAudience = val!)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isMapView 
              ? _buildMapView() 
              : StreamBuilder<List<ClassModel>>(
                  stream: _classesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allClasses = snapshot.data ?? [];
                    
                    // Client-side filtering
                    final filteredClasses = allClasses.where((cls) {
                      // 1. Search Term
                      final matchesSearch = _searchTerm.isEmpty || 
                          cls.title.toLowerCase().contains(_searchTerm.toLowerCase()) || 
                          cls.instructorName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                          cls.discipline.toLowerCase().contains(_searchTerm.toLowerCase()); // Also search discipline

                      if (!matchesSearch) return false;

                      // 2. Region Filter (Strict)
                      if (_selectedRegion != 'Todas') {
                        final bool regionMatch = (cls.region.isNotEmpty && cls.region == _selectedRegion) ||
                                                 (cls.location.toLowerCase().contains(_selectedRegion.toLowerCase()));
                        if (!regionMatch) return false;
                      }

                      // 3. Comuna Filter (Strict)
                      if (_selectedComuna != 'Todas') {
                         final bool comunaMatch = (cls.comuna.isNotEmpty && cls.comuna == _selectedComuna) ||
                                                  (cls.location.toLowerCase().contains(_selectedComuna.toLowerCase()));
                         if (!comunaMatch) return false;
                      }

                      // 4. Category Filter (Strict)
                      if (_selectedCategory != 'Todas') {
                        // Match on Category OR fuzzy match on Discipline (e.g. search "Salsa" if category is "Baile" might be overkill, sticking to strict category)
                        // Actually, CreateClassScreen saves 'Baile', 'Fitness' etc. into cls.category.
                        // So exact match is correct.
                        bool matchesCategory = (cls.category.toLowerCase() == _selectedCategory.toLowerCase());
                        
                        // Safety fallback: if category not set, check if discipline is in known subcategories (Simplified)
                        if (!matchesCategory && cls.category.isEmpty) {
                           // This is just a robust fallback
                           matchesCategory = cls.discipline.toLowerCase().contains(_selectedCategory.toLowerCase());
                        }

                        if (!matchesCategory) return false;
                      }

                      // 5. Audience Filter (Strict)
                      if (_selectedAudience != 'Todas') {
                        if (cls.targetAudience != _selectedAudience) return false;
                      }

                      return true;
                    }).toList();

                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: const Color(0xFFD000FF),
                      child: filteredClasses.isEmpty 
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: constraints.maxHeight,
                                child: Center(child: Text(allClasses.isEmpty ? 'No se encontraron clases.' : 'No hay coincidencias.')),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredClasses.length,
                            itemBuilder: (context, index) => _buildCompactClassCard(filteredClasses[index]),
                          ),
                    );
                  }
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    final isDefault = value == 'Todas' || value == 'Todos';
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFFD000FF);

    return Container(
      decoration: BoxDecoration(
        color: isDefault ? theme.cardTheme.color : primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDefault ? Colors.grey.withOpacity(0.3) : primaryColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.arrow_drop_down, color: isDefault ? Colors.grey : primaryColor),
          style: TextStyle(
             color: isDefault ? theme.textTheme.bodyLarge?.color : primaryColor,
             fontWeight: isDefault ? FontWeight.normal : FontWeight.bold,
             fontSize: 12,
          ),
          items: options.map((o) => DropdownMenuItem(
            value: o,
            child: Text(o == options.first ? '$label: $o' : o),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCompactClassCard(ClassModel cls) {
    final isFull = cls.attendeeIds.length >= cls.capacity;
    
    // Placeholder Data for fields not yet in ClassModel
    const imageUrl = 'https://picsum.photos/300/200'; // Random Unsplash
    // const rating = 5.0; // Default
    // const category = 'General'; // Default

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column( // Main Column
        children: [
           // IMAGE + INFO (Clickable Row)
           GestureDetector( 
             onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StudentClassDetailScreen(classData: cls)
                ));
             },
             child: IntrinsicHeight(
               child: Row(
               crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure image fills height
               children: [
                 // 1. Image
                 Stack(
                   children: [
                      Container(
                        width: 110,
                        // Height determined by parent IntrinsicHeight
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)), // Fix corner radius
                          image: const DecorationImage(
                            image: NetworkImage(imageUrl), 
                            fit: BoxFit.cover,
                          ),
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (isFull)
                        Container(
                          width: 110, 
                          alignment: Alignment.center,
                          color: Colors.black.withOpacity(0.5),
                          child: const Text('FULL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                   ],
                 ),
                 
                 // 2. Info
                 Expanded(
                   child: Padding(
                     padding: const EdgeInsets.all(10),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         // Title + Price Row
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Expanded(
                               child: Text(
                                 cls.title, 
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                 maxLines: 1, 
                                 overflow: TextOverflow.ellipsis
                               ),
                             ),
                             Text('\$${NumberFormat('#,###').format(cls.price)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonGreen, fontSize: 14)),
                           ],
                         ),
                         
                         // Plan Badge
                         if (cls.availablePlans.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(top: 4, bottom: 4),
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: Colors.amber.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(4),
                                 border: Border.all(color: Colors.amber, width: 0.5)
                               ),
                               child: const Text('Plans Disponibles ⭐', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                             ),
                           ),
                         
                         // Instructor Link
                         Row(
                           children: [
                               const Icon(Icons.person, size: 12, color: AppColors.neonPurple),
                               const SizedBox(width: 4),
                               Expanded(child: Text(cls.instructorName.isNotEmpty ? cls.instructorName : 'Instructor', style: const TextStyle(fontSize: 12, color: AppColors.neonPurple, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                           ],
                         ),
                         
                         // Date + Time
                         Text(
                           '${DateFormat('EEEE d', 'es_ES').format(cls.date)} • ${cls.startTime}',
                           style: const TextStyle(fontSize: 12, color: Colors.grey),
                         ),
                         
                         // Commune + Availability
                         Row(
                           children: [
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                               child: Text(cls.location, style: const TextStyle(fontSize: 10, color: Colors.grey)), 
                             ),
                             const Spacer(),
                             if (!isFull)
                               Text('${cls.capacity - cls.attendeeIds.length} cupos', style: const TextStyle(fontSize: 11, color: AppColors.neonGreen, fontWeight: FontWeight.bold))
                           ],
                         ),
                       ],
                     ),
                   ),
                 )
               ],
             ),
           ) 
          )
        ],
      ),
    );
  }

  void _showPlansMenu(BuildContext context, List plans, int basePrice) async {
     // Removed for now as Plans are not in ClassModel
  }

  Widget _buildMapView() {
    return StreamBuilder<List<ClassModel>>(
      stream: _classesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        
        final allClasses = snapshot.data ?? [];
        
        // Use same filters but slightly relaxed for Map to show nearby things?
        // For now, keep consistent.
        final filteredClasses = allClasses.where((cls) {
          // ensure lat/lng is valid first
          if (cls.latitude == null || cls.longitude == null) return false;

          final matchesSearch = _searchTerm.isEmpty || 
              cls.title.toLowerCase().contains(_searchTerm.toLowerCase()) || 
              cls.instructorName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
              cls.discipline.toLowerCase().contains(_searchTerm.toLowerCase());
          if (!matchesSearch) return false;
          
          if (_selectedRegion != 'Todas') {
             final bool regionMatch = (cls.region.isNotEmpty && cls.region == _selectedRegion) ||
                                      (cls.location.toLowerCase().contains(_selectedRegion.toLowerCase()));
             if (!regionMatch) return false;
          }
          if (_selectedComuna != 'Todas') {
             final bool comunaMatch = (cls.comuna.isNotEmpty && cls.comuna == _selectedComuna) ||
                                      (cls.location.toLowerCase().contains(_selectedComuna.toLowerCase()));
             if (!comunaMatch) return false;
          }
          if (_selectedCategory != 'Todas') {
             bool matchesCategory = (cls.category.toLowerCase() == _selectedCategory.toLowerCase());
             if (!matchesCategory && cls.category.isEmpty) {
                matchesCategory = cls.discipline.toLowerCase().contains(_selectedCategory.toLowerCase());
             }
             if (!matchesCategory) return false;
          }
          if (_selectedAudience != 'Todas') {
            if (cls.targetAudience != _selectedAudience && cls.targetAudience != 'Todos') return false; // Relax audience?
          }
          return true;
        }).toList();

        final Set<Marker> markers = filteredClasses
            .where((c) => c.latitude != null && c.longitude != null)
            .map((c) => Marker(
              markerId: MarkerId(c.id),
              position: LatLng(c.latitude!, c.longitude!),
              infoWindow: InfoWindow(
                title: c.title,
                snippet: '${c.startTime} - ${c.instructorName}',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentClassDetailScreen(classData: c))),
              ),
            )).toSet();

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _userLocation ?? _defaultLocation,
            zoom: _userLocation != null ? 14.0 : 12.0, // Closer zoom if location is known
          ),
          markers: markers,
          myLocationEnabled: true, 
          myLocationButtonEnabled: true,
          onMapCreated: (GoogleMapController controller) {
             _mapController = controller;
             if (_userLocation != null) {
                  _mapController!.animateCamera(
                     CameraUpdate.newCameraPosition(
                       CameraPosition(target: _userLocation!, zoom: 14.0)
                     )
                   );
             }
          },
        );
      }
    );
  }
}
