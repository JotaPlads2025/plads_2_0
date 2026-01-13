import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastModel {
  final String id;
  final String instructorId;
  final String title;
  final String message;
  final String audienceType; // 'active_students', 'followers', 'interests', 'all'
  final List<String>? targetInterests; // e.g. ['Salsa', 'Bachata']
  final DateTime timestamp;
  final int reachCount; // Approx number of users sent to

  BroadcastModel({
    required this.id,
    required this.instructorId,
    required this.title,
    required this.message,
    required this.audienceType,
    this.targetInterests,
    required this.timestamp,
    this.reachCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'instructorId': instructorId,
      'title': title,
      'message': message,
      'audienceType': audienceType,
      'targetInterests': targetInterests,
      'timestamp': Timestamp.fromDate(timestamp),
      'reachCount': reachCount,
    };
  }

  factory BroadcastModel.fromMap(Map<String, dynamic> map) {
    return BroadcastModel(
      id: map['id'] ?? '',
      instructorId: map['instructorId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      audienceType: map['audienceType'] ?? 'active_students',
      targetInterests: map['targetInterests'] != null ? List<String>.from(map['targetInterests']) : null,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      reachCount: map['reachCount'] ?? 0,
    );
  }
}
