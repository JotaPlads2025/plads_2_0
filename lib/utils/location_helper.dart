import 'package:geocoding/geocoding.dart';

class LocationHelper {
  
  // Data Source (Should match what's used in the app screens)
  static final Map<String, List<String>> communesByRegion = {
    'Metropolitana': ['Santiago', 'Providencia', 'Las Condes', 'Ñuñoa', 'La Florida', 'Maipú', 'Vitacura', 'La Reina', 'Peñalolén', 'Macul', 'San Miguel', 'Estación Central', 'Recoleta', 'Huechuraba', 'Pudahuel', 'Quilicura', 'Lo Barnechea', 'Cerrillos'],
    'Valparaíso': ['Valparaíso', 'Viña del Mar', 'Concón', 'Quilpué', 'Villa Alemana'],
    'Biobío': ['Concepción', 'Talcahuano', 'San Pedro de la Paz', 'Chiguayante'],
    'O\'Higgins': ['Rancagua', 'Machalí'],
    'Maule': ['Talca', 'Curicó'],
  };

  static const List<String> regions = ['Metropolitana', 'Valparaíso', 'Biobío', 'O\'Higgins', 'Maule'];

  /// Tries to match a raw region string (e.g. "Región Metropolitana de Santiago") to our simplified list.
  /// Returns the matched key or null if no match found.
  static String? matchRegion(String? input) {
    if (input == null || input.isEmpty) return null;
    
    final normalized = input.toLowerCase();

    if (normalized.contains('metropolitana') || normalized.contains('santiago') || normalized == 'rm') {
      return 'Metropolitana';
    }
    if (normalized.contains('valpara') || normalized.contains('valpo') || normalized == 'v región') {
      return 'Valparaíso';
    }
    if (normalized.contains('biobío') || normalized.contains('bio bio') || normalized.contains('concepción') || normalized == 'viii región') {
      return 'Biobío';
    }
    if (normalized.contains('higgins') || normalized.contains('rancagua') || normalized == 'vi región') {
      return 'O\'Higgins';
    }
    if (normalized.contains('maule') || normalized.contains('talca') || normalized == 'vii región') {
      return 'Maule';
    }

    // Try exact match against keys
    for (var key in regions) {
      if (key.toLowerCase() == normalized) return key;
    }

    return null; 
  }

  /// Tries to match a raw commune string to the list of communes in a specific region.
  static String? matchCommune(String region, String? input) {
    if (input == null || input.isEmpty) return null;
    if (!communesByRegion.containsKey(region)) return null;

    final normalized = input.toLowerCase();
    final validCommunes = communesByRegion[region]!;

    // 1. Exact Match (Case Insensitive)
    try {
      return validCommunes.firstWhere((c) => c.toLowerCase() == normalized);
    } catch (_) {}

    // 2. Contains Match (e.g. "Comuna de Providencia" -> "Providencia")
    try {
       return validCommunes.firstWhere((c) => normalized.contains(c.toLowerCase()));
    } catch (_) {}

    // 3. Reverse Contains (e.g. "Providencia" matches part of "Nueva Providencia" - unlikely but possible)
    try {
       return validCommunes.firstWhere((c) => c.toLowerCase().contains(normalized));
    } catch (_) {}
    
    return null;
  }

  /// Extracts a readable address from a Placemark
  static String formatAddress(Placemark place) {
    String address = '';
    if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      address = place.thoroughfare!;
      if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
        address += ' ${place.subThoroughfare}';
      }
    } else {
      // Fallback
      address = place.name ?? ''; 
    }
    return address;
  }
}
