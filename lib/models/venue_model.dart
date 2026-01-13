class VenueModel {
  final String id;
  final String name;
  final String address;
  final String region;
  final String commune;
  final double? latitude;
  final double? longitude;

  VenueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.region,
    required this.commune,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'region': region,
      'commune': commune,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory VenueModel.fromMap(Map<String, dynamic> map) {
    return VenueModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      region: map['region'] ?? '',
      commune: map['commune'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }
}
