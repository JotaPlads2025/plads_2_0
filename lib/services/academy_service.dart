
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/academy_model.dart';
import '../models/room_model.dart';
import '../models/staff_member.dart';

class AcademyService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AcademyModel? _currentAcademy;
  AcademyModel? get currentAcademy => _currentAcademy;

  // Load Academy for User
  Future<void> loadAcademy(String instructorId) async {
    try {
      final snapshot = await _db.collection('academies')
          .where('instructorId', isEqualTo: instructorId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        _currentAcademy = AcademyModel.fromMap(snapshot.docs.first.data());
      } else {
        _currentAcademy = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading academy: $e');
      _currentAcademy = null;
      notifyListeners();
    }
  }

  Future<void> createAcademy({
    required String instructorId, 
    required String name,
    required String address,
    required String subdomain,
    required Color primaryColor,
    String region = 'Metropolitana',
    String commune = 'Providencia',
    double? latitude,
    double? longitude,
    String? logoUrl,
  }) async {
    try {
      final docRef = _db.collection('academies').doc();
      final newAcademy = AcademyModel(
        id: docRef.id,
        instructorId: instructorId,
        name: name,
        address: address,
        subdomain: subdomain,
        primaryColor: primaryColor,
        region: region,
        commune: commune,
        latitude: latitude,
        longitude: longitude,
        logoUrl: logoUrl,
        createdAt: DateTime.now(),
      );
      
      await docRef.set(newAcademy.toMap());
      _currentAcademy = newAcademy;
      notifyListeners();
    } catch (e) {
      print('Error creating academy: $e');
      rethrow;
    }
  }

  Future<void> updateAcademyInfo({
    required String academyId,
    required String name,
    required String address,
    required String region,
    required String commune,
    required String subdomain,
    double? latitude, // New
    double? longitude, // New
    Map<String, String>? socialLinks,
  }) async {
    if (_currentAcademy == null) return;
    try {
      final updatedAcademy = _currentAcademy!.copyWith(
        name: name,
        address: address,
        region: region,
        commune: commune,
        subdomain: subdomain,
        socialLinks: socialLinks,
        latitude: latitude,
        longitude: longitude,
      );
      
      await _db.collection('academies').doc(academyId).update(updatedAcademy.toMap());
      _currentAcademy = updatedAcademy;
      notifyListeners();
    } catch (e) {
      print('Error updating academy info: $e');
      rethrow;
    }
  }

  Future<void> updateBranding({
    required String academyId,
    required String address,
    required String subdomain,
    required Color primaryColor,
    String? logoUrl,
  }) async {
    if (_currentAcademy == null) return;
    try {
      final updatedAcademy = _currentAcademy!.copyWith(
        address: address,
        subdomain: subdomain,
        primaryColor: primaryColor,
        logoUrl: logoUrl,
      );
      
      await _db.collection('academies').doc(academyId).update(updatedAcademy.toMap());
      _currentAcademy = updatedAcademy;
      notifyListeners();
    } catch (e) {
      print('Error updating branding: $e');
      rethrow;
    }
  }

  Future<void> addRoom({
    required String academyId,
    required RoomModel room,
  }) async {
    if (_currentAcademy == null) return;
    try {
      final updatedRooms = List<RoomModel>.from(_currentAcademy!.rooms)..add(room);
      final updatedAcademy = _currentAcademy!.copyWith(rooms: updatedRooms);
      
      // Update whole object for simplicity (or use arrayUnion if preferable)
      await _db.collection('academies').doc(academyId).update({
        'rooms': updatedRooms.map((r) => r.toMap()).toList()
      });
      
      _currentAcademy = updatedAcademy;
      notifyListeners();
    } catch (e) {
       print('Error adding room: $e');
       rethrow;
    }
  }

  Future<void> removeRoom({
    required String academyId,
    required String roomId,
  }) async {
    if (_currentAcademy == null) return;
    try {
      final updatedRooms = List<RoomModel>.from(_currentAcademy!.rooms)..removeWhere((r) => r.id == roomId);
      final updatedAcademy = _currentAcademy!.copyWith(rooms: updatedRooms);
      
      await _db.collection('academies').doc(academyId).update({
         'rooms': updatedRooms.map((r) => r.toMap()).toList()
      });
      
      _currentAcademy = updatedAcademy;
      notifyListeners();
    } catch (e) {
       print('Error removing room: $e');
       rethrow;
    }
  }

  Future<void> addStaff({
    required String academyId,
    required StaffMember staffMember,
  }) async {
    if (_currentAcademy == null) return;
    try {
      final updatedStaff = List<StaffMember>.from(_currentAcademy!.staff)..add(staffMember);
      final updatedAcademy = _currentAcademy!.copyWith(staff: updatedStaff);
      
      await _db.collection('academies').doc(academyId).update({
         'staff': updatedStaff.map((s) => s.toMap()).toList()
      });
      
      _currentAcademy = updatedAcademy;
      notifyListeners();
    } catch (e) {
       print('Error adding staff: $e');
       rethrow;
    }
  }

  Future<void> removeStaff({
    required String academyId,
    required String staffEmail,
  }) async {
    if (_currentAcademy == null) return;
    try {
      final updatedStaff = List<StaffMember>.from(_currentAcademy!.staff)..removeWhere((s) => s.email == staffEmail);
      final updatedAcademy = _currentAcademy!.copyWith(staff: updatedStaff);
      
      await _db.collection('academies').doc(academyId).update({
         'staff': updatedStaff.map((s) => s.toMap()).toList()
      });
      
      _currentAcademy = updatedAcademy;
      notifyListeners();
    } catch (e) {
       print('Error removing staff: $e');
       rethrow;
    }
  }

  Future<void> deleteAcademy(String academyId) async {
    try {
      await _db.collection('academies').doc(academyId).delete();
      _currentAcademy = null;
      notifyListeners();
    } catch (e) {
      print('Error deleting academy: $e');
      rethrow;
    }
  }
}
