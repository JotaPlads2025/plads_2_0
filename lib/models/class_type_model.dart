class ClassType {
  final String id;
  final String instructorId; // 'GLOBAL' for official Plads types, or Instructor UID for custom
  final String name; // Now derived: "$discipline $level"
  final String discipline; // e.g. "Salsa", "Bachata"
  final String level; // e.g. "Básico", "Intermedio"
  final String targetAudience; // e.g. "Mujeres", "Niños"
  final String category; // e.g. "Fitness", "Dance", "Other"
  final bool isVerified; // true = Official, false = Custom
  final String color; // Hex string e.g. "#FF00FF"
  
  // Default values for faster creation
  final int defaultDuration; // minutes
  final double defaultPrice;
  final int defaultCapacity;

  ClassType({
    required this.id,
    required this.instructorId,
    required this.name,
    this.discipline = '', // New field default
    this.level = '', // New field default
    this.targetAudience = 'Todo Público', // New field default
    required this.category,
    this.isVerified = false,
    this.color = '#39FF14', // Default Neon Green
    this.defaultDuration = 60,
    this.defaultPrice = 5000,
    this.defaultCapacity = 20,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'instructorId': instructorId,
      'name': name,
      'discipline': discipline,
      'level': level,
      'targetAudience': targetAudience, // New: Audience
      'category': category,
      'isVerified': isVerified,
      'color': color,
      'defaultDuration': defaultDuration,
      'defaultPrice': defaultPrice,
      'defaultCapacity': defaultCapacity,
    };
  }

  factory ClassType.fromMap(Map<String, dynamic> map) {
    return ClassType(
      id: map['id'] ?? '',
      instructorId: map['instructorId'] ?? '',
      name: map['name'] ?? '',
      discipline: map['discipline'] ?? '',
      level: map['level'] ?? '',
      targetAudience: map['targetAudience'] ?? 'Todo Público',
      category: map['category'] ?? 'Other',
      isVerified: map['isVerified'] ?? false,
      color: map['color'] ?? '#39FF14',
      defaultDuration: map['defaultDuration'] ?? 60,
      defaultPrice: (map['defaultPrice'] ?? 0).toDouble(),
      defaultCapacity: map['defaultCapacity'] ?? 20,
    );
  }
}
