import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String instructorId;
  final String instructorName; // Denormalized for Search
  final String title;
  final String description;
  final DateTime date;
  final String startTime; // Format "HH:mm"
  final String endTime;   // Format "HH:mm"
  final int capacity;
  final double price;
  final String location;
  final List<String> attendeeIds;
  final Map<String, dynamic> attendance; // Map userId -> timestamp
  final List<Map<String, dynamic>> manualAttendees; // New field for manually added students
  final String status; // 'active', 'cancelled', 'completed'
  final String? cancellationReason; // New field for cancellation reason
  final String? classTypeId; // Link to ClassType
  final String category; // Joined from ClassType for search
  final String discipline; // Joined from ClassType for search
  final String level;      // New field - e.g. "Básico", "Intermedio"
  final String targetAudience; // e.g. "Mujeres", "Niños"
  final String region; // e.g. "Metropolitana"
  final String comuna; // e.g. "Providencia"
  final double? latitude;
  final double? longitude;
  final String color; // Visual color for calendar
  final String? imageUrl; // New field for class image
  final List<Map<String, dynamic>> availablePlans; // New: List of plans (title, price, credits)

  ClassModel({
    required this.id,
    required this.instructorId,
    this.instructorName = '', 
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.price,
    required this.location,
    this.attendeeIds = const [],
    this.attendance = const {},
    this.manualAttendees = const [], 
    this.status = 'active',
    this.cancellationReason,
    this.classTypeId,
    this.category = '', // Default empty
    this.discipline = '', // Default empty
    this.level = 'All', // Default
    this.targetAudience = 'Todo Público', // Default
    this.region = '', // Default
    this.comuna = '', // Default
    this.latitude,
    this.longitude,
    this.color = '#39FF14', // Default Neon Green
    this.imageUrl,
    this.availablePlans = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'capacity': capacity,
      'price': price,
      'location': location,
      'attendeeIds': attendeeIds,
      'attendance': attendance,
      'manualAttendees': manualAttendees,
      'status': status,
      'cancellationReason': cancellationReason,
      'classTypeId': classTypeId,
      'category': category, // Save to DB
      'discipline': discipline, // Save to DB
      'level': level, // New
      'targetAudience': targetAudience, // New
      'region': region, // New
      'comuna': comuna, // New
      'latitude': latitude,
      'longitude': longitude,
      'color': color,
      'imageUrl': imageUrl,
      'availablePlans': availablePlans,
    };
  }

  // Create from Firestore Document
  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] ?? '',
      instructorId: map['instructorId'] ?? '',
      instructorName: map['instructorName'] ?? 'Instructor',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      capacity: map['capacity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      attendeeIds: List<String>.from(map['attendeeIds'] ?? []),
      attendance: Map<String, dynamic>.from(map['attendance'] ?? {}),
      manualAttendees: List<Map<String, dynamic>>.from(map['manualAttendees'] ?? []), 
      status: map['status'] ?? 'active',
      cancellationReason: map['cancellationReason'],
      classTypeId: map['classTypeId'],
      category: map['category'] ?? '', // Load from DB
      discipline: map['discipline'] ?? '', // Load from DB
      level: map['level'] ?? 'All',
      targetAudience: map['targetAudience'] ?? 'Todo Público',
      region: map['region'] ?? '',
      comuna: map['comuna'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      color: map['color'] ?? '#39FF14',
      imageUrl: map['imageUrl'], // Load from DB
      availablePlans: List<Map<String, dynamic>>.from(map['availablePlans'] as List<dynamic>? ?? []),
    );
  }
}
