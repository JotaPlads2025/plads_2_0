
import 'package:flutter/material.dart';

class StaffMember {
  final String? userId; // Null if not yet registered/linked
  final String email;
  final String name;
  final String role; // 'Instructor', 'Assistant', 'Admin'
  final String status; // 'Active', 'Pending'
  final Color? color; // Avatar color

  StaffMember({
    this.userId,
    required this.email,
    required this.name,
    required this.role,
    this.status = 'Pending',
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'color': color?.value,
    };
  }

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      userId: map['userId'],
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'Instructor',
      status: map['status'] ?? 'Pending',
      color: map['color'] != null ? Color(map['color']) : null,
    );
  }
}
