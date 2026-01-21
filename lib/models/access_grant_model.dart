enum AccessGrantType {
  pack,      // Cantidad finita de clases (ej. 4 clases)
  subscription // Duración de tiempo (ej. 1 mes)
}

class AccessGrant {
  final String id;
  final String name; // Ej: "Pack Salsa 4", "Plan Full Mensual"
  final AccessGrantType type;
  
  // Scope / Alcance
  final String instructorId; // New: Strict ownership
  final String discipline; // Ej: "Salsa", "Bachata", "All"
  final String level;      // Ej: "Initial", "Intermediate", "All"
  final String category;   // Ej: "Baile", "Fitness"
  
  // Validity / Validez
  final int? remainingClasses; // Solo para type == pack
  final int? initialClasses;   // Para tracker progreso (ej. 3 de 4)
  final DateTime? expiryDate;  // Para ambos (Pack vence, Subs vence)
  
  final bool isActive;

  AccessGrant({
    required this.id,
    required this.name,
    required this.type,
    required this.instructorId,
    this.discipline = 'All',
    this.level = 'All',
    this.category = 'All',
    this.remainingClasses,
    this.initialClasses,
    this.expiryDate,
    this.isActive = true,
  });

  // Helpers
  bool isValidForClass(String classInstructorId, String classDiscipline, String classLevel, String classCategory, DateTime classDate) {
    if (!isActive) return false;
    if (expiryDate != null && classDate.isAfter(expiryDate!)) return false;
    
    // Strict Instructor Check
    if (instructorId != classInstructorId) return false;

    // Check Scope matches (Simple implementation: 'All' or exact match)
    bool disciplineMatch = discipline == 'All' || discipline.toLowerCase() == classDiscipline.toLowerCase();
    bool categoryMatch = category == 'All' || category.toLowerCase() == classCategory.toLowerCase();
    
    // Level matching might be trickier, for now strict or 'All'
    bool levelMatch = level == 'All' || level.toLowerCase() == classLevel.toLowerCase();

    if (type == AccessGrantType.pack) {
      return (remainingClasses ?? 0) > 0 && disciplineMatch && categoryMatch && levelMatch;
    } else {
      // Subscription
      return disciplineMatch && categoryMatch && levelMatch;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name, // enum index or name
      'instructorId': instructorId,
      'discipline': discipline,
      'level': level,
      'category': category,
      'remainingClasses': remainingClasses,
      'initialClasses': initialClasses,
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AccessGrant.fromMap(Map<String, dynamic> map) {
    return AccessGrant(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Plan',
      type: AccessGrantType.values.firstWhere(
        (e) => e.name == map['type'], 
        orElse: () => AccessGrantType.subscription
      ),
      instructorId: map['instructorId'] ?? '',
      discipline: map['discipline'] ?? 'All',
      level: map['level'] ?? 'All',
      category: map['category'] ?? 'All',
      remainingClasses: map['remainingClasses'],
      initialClasses: map['initialClasses'],
      expiryDate: map['expiryDate'] is String 
          ? DateTime.parse(map['expiryDate']) 
          : (map['expiryDate'] as dynamic)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}
