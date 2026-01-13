
class RoomModel {
  final String id;
  final String name;
  final int capacity;
  final String? description;

  RoomModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'description': description,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      capacity: map['capacity'] ?? 0,
      description: map['description'],
    );
  }
}
