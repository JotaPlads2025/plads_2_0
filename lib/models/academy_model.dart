
import 'package:flutter/material.dart';
import 'room_model.dart';
import 'staff_member.dart';

class AcademyModel {
  final String id;
  final String instructorId;
  final String name;
  final String address;
  final String subdomain;
  final Color primaryColor;
  final String? logoUrl;
  final bool isActive;
  final String country; // 'CL', 'PE', 'BR', etc.
  final String region;
  final String commune;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final List<RoomModel> rooms;
  final List<StaffMember> staff;
  final Map<String, String> socialLinks; // New

  AcademyModel({
    required this.id,
    required this.instructorId,
    required this.name,
    this.address = '',
    required this.subdomain,
    required this.primaryColor,
    this.logoUrl,
    this.isActive = true,
    this.country = 'CL', // Default to Chile
    this.region = 'Metropolitana',
    this.commune = 'Providencia',
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.rooms = const [],
    this.staff = const [],
    this.socialLinks = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'instructorId': instructorId,
      'name': name,
      'address': address,
      'subdomain': subdomain,
      'primaryColor': primaryColor.value,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'country': country,
      'region': region,
      'commune': commune,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'rooms': rooms.map((x) => x.toMap()).toList(),
      'staff': staff.map((x) => x.toMap()).toList(),
      'socialLinks': socialLinks,
    };
  }

  factory AcademyModel.fromMap(Map<String, dynamic> map) {
    return AcademyModel(
      id: map['id'] ?? '',
      instructorId: map['instructorId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      subdomain: map['subdomain'] ?? '',
      primaryColor: map['primaryColor'] != null 
          ? Color(map['primaryColor']) 
          : const Color(0xFFD000FF),
      logoUrl: map['logoUrl'],
      isActive: map['isActive'] ?? true,
      country: map['country'] ?? 'CL',
      region: map['region'] ?? 'Metropolitana',
      commune: map['commune'] ?? 'Providencia',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      rooms: map['rooms'] != null 
          ? List<RoomModel>.from(map['rooms']?.map((x) => RoomModel.fromMap(x)))
          : [],
      staff: map['staff'] != null 
          ? List<StaffMember>.from(map['staff']?.map((x) => StaffMember.fromMap(x)))
          : [],
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
    );
  }

  AcademyModel copyWith({
    String? name,
    String? address,
    String? subdomain,
    Color? primaryColor,
    String? logoUrl,
    bool? isActive,
    String? country,
    String? region,
    String? commune,
    double? latitude,
    double? longitude,
    List<RoomModel>? rooms,
    List<StaffMember>? staff,
    Map<String, String>? socialLinks,
  }) {
    return AcademyModel(
      id: id,
      instructorId: instructorId,
      name: name ?? this.name,
      address: address ?? this.address,
      subdomain: subdomain ?? this.subdomain,
      primaryColor: primaryColor ?? this.primaryColor,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      country: country ?? this.country,
      region: region ?? this.region,
      commune: commune ?? this.commune,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      rooms: rooms ?? this.rooms,
      staff: staff ?? this.staff,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}
