import 'dart:ui';
import 'package:flutter/material.dart';
import 'access_grant_model.dart';

enum StudentStatus { activePlan, dropIn, inactive }

class StudentModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final StudentStatus status;
  final DateTime? lastAttendance;
  final DateTime? joinDate;
  
  // Plan details (New Multi-Plan structure)
  final List<AccessGrant> activeSubscriptions;

  // Deprecated Single Plan Fields (kept nullable for backward compat if needed, but removal is cleaner)
  // final String? planName;
  // final int? creditsRemaining;
  // ...

  // DropIn details
  final String? paymentMethod;

  final Map<String, dynamic> wallet; // { instructorId: { balance: int, instructorName: String } }

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.status,
    this.lastAttendance,
    this.joinDate,
    this.activeSubscriptions = const [],
    this.paymentMethod,
    this.wallet = const {},
  });

  // UI Helpers
  String get initials => name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join();
  
  Color get avatarColor {
    // Generate a consistent color based on the name hash
    final int hash = name.hashCode;
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];
    return colors[hash.abs() % colors.length];
  }

  // Helper to check general validity (e.g. for "Active" status badge)
  bool get hasActivePlan => activeSubscriptions.any((g) => g.isActive && (g.type == AccessGrantType.subscription ? (g.expiryDate == null || g.expiryDate!.isAfter(DateTime.now())) : (g.remainingClasses ?? 0) > 0));

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'status': status.name, // Enum to string
      'lastAttendance': lastAttendance?.toIso8601String(),
      'joinDate': joinDate?.toIso8601String(),
      'activeSubscriptions': activeSubscriptions.map((x) => x.toMap()).toList(),
      'paymentMethod': paymentMethod,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['displayName'] ?? map['name'] ?? 'Sin Nombre',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      status: StudentStatus.values.firstWhere(
        (e) => e.name == map['status'], 
        orElse: () => StudentStatus.dropIn 
      ),
      lastAttendance: map['lastAttendance'] != null ? DateTime.parse(map['lastAttendance']) : null,
      joinDate: map['joinDate'] != null 
          ? DateTime.parse(map['joinDate']) 
          : (map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null),
      activeSubscriptions: map['activeSubscriptions'] != null 
          ? List<AccessGrant>.from((map['activeSubscriptions'] as List).map((x) => AccessGrant.fromMap(x)))
          : [], // Handle legacy migration here if needed by reading old fields
      paymentMethod: map['paymentMethod'],
      wallet: Map<String, dynamic>.from(map['wallet'] ?? {}),
    );
  }
}
