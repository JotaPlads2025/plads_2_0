import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialPosition;

  const MapPickerScreen({
    super.key,
    this.initialPosition = const LatLng(-33.4489, -70.6693), // Santiago Default
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _currentPosition;
  GoogleMapController? _mapController;
  
  String? _currentAddress;
  String? _currentCommune;
  String? _currentRegion;
  bool _isLoadingAddress = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _getAddress(_currentPosition);
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position.target;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Debounce the geocoding request to save API calls and UI flicker
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _getAddress(_currentPosition);
    });
  }

  Future<void> _getAddress(LatLng position) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);
    
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Construct a readable address
        String street = place.thoroughfare ?? '';
        String number = place.subThoroughfare ?? '';
        
        setState(() {
          _currentAddress = '$street $number'.trim();
          if (_currentAddress!.isEmpty) _currentAddress = place.name; // Fallback
          
          _currentCommune = place.subLocality ?? place.locality; // Often Comuna is in subLocality
          _currentRegion = place.administrativeArea;
        });
      }
    } catch (e) {
      debugPrint("Error geocoding: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Return a Map with all details
              final result = {
                'latLng': _currentPosition,
                'address': _currentAddress,
                'commune': _currentCommune,
                'region': _currentRegion,
              };
              Navigator.pop(context, result);
            },
            child: const Text('CONFIRMAR', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            padding: const EdgeInsets.only(bottom: 100), // Push Google logo up
          ),
          
          // Fixed Center Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 20), // Adjust for marker tip
              child: Icon(Icons.location_on, size: 40, color: AppColors.neonPurple),
            ),
          ),
          
          // Address Overlay
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingAddress)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                         SizedBox(width: 8),
                         Text('Buscando dirección...', style: TextStyle(color: Colors.grey))
                      ],
                    )
                  else 
                    Column(
                      children: [
                        Text(
                          _currentAddress ?? 'Ubicación Desconocida',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        if (_currentCommune != null || _currentRegion != null)
                           Text(
                            '${_currentCommune ?? ''}, ${_currentRegion ?? ''}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mueve el mapa para ajustar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.neonPurple, fontSize: 10),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
