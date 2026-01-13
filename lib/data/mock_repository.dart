import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/access_grant_model.dart';
import '../models/transaction_model.dart';

class MockRepository {
  // Singleton pattern to ensure same instance is used everywhere (simulating DB)
  static final MockRepository _instance = MockRepository._internal();
  factory MockRepository() => _instance;
  MockRepository._internal();

  // --- DATA STORAGE ---
  
  final List<StudentModel> students = [
    // --- Subscribers ---
    StudentModel(
      id: '1',
      name: 'Camila Rodriguez',
      email: 'camila@test.com', // Added mock email
      status: StudentStatus.activePlan,
      activeSubscriptions: [
        AccessGrant(
          id: 'g3', 
          name: 'Pack 4 Clases', 
          type: AccessGrantType.pack, 
          instructorId: 'inst1', // Default mock instructor
          initialClasses: 4, 
          remainingClasses: 1,
          discipline: 'All', 
          level: 'All'
        )
      ],
      lastAttendance: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StudentModel(
      id: '2',
      name: 'Felipe Muñoz',
      email: 'felipe@test.com',
      status: StudentStatus.activePlan,
      activeSubscriptions: [
        AccessGrant(
          id: 'g2', 
          name: 'Mensual Ilimitado', 
          type: AccessGrantType.subscription, 
          instructorId: 'inst1', // Added default
          expiryDate: DateTime.now().add(const Duration(days: 15)),
          discipline: 'All', 
          level: 'All'
        )
      ],
      lastAttendance: DateTime.now().subtract(const Duration(days: 1)),
    ),
    StudentModel(
      id: '3',
      name: 'Andrea Soto',
      email: 'andrea@test.com',
      status: StudentStatus.activePlan,
      activeSubscriptions: [
        AccessGrant(
          id: 'g1', 
          name: 'Pack Salsa 8', 
          type: AccessGrantType.pack, 
          instructorId: 'inst1',
          discipline: 'Salsa', 
          remainingClasses: 6, 
          initialClasses: 8,
          expiryDate: DateTime.now().add(const Duration(days: 20))
        ),
        AccessGrant(
          id: 'g2', 
          name: 'Mensual Bachata', 
          type: AccessGrantType.subscription, 
          instructorId: 'inst1',
          discipline: 'Bachata',
          expiryDate: DateTime.now().add(const Duration(days: 15))
        ),
      ],
      lastAttendance: DateTime.now().subtract(const Duration(days: 5)),
    ),
    
    // --- Drop Ins ---
    StudentModel(
      id: '4',
      name: 'Jose Ballesteros',
      email: 'jose@test.com',
      status: StudentStatus.dropIn,
      lastAttendance: DateTime.now().subtract(const Duration(days: 3)),
      paymentMethod: 'App Plads',
    ),
    StudentModel(
      id: '5',
      name: 'Lucía Méndez',
      email: 'lucia@test.com',
      status: StudentStatus.dropIn,
      lastAttendance: DateTime.now().subtract(const Duration(days: 7)),
      paymentMethod: 'Efectivo',
    ),
    StudentModel(
      id: '6',
      name: 'Pablo Ruiz',
      email: 'pablo@test.com',
      status: StudentStatus.dropIn,
      lastAttendance: DateTime.now().subtract(const Duration(days: 12)),
      paymentMethod: 'Transferencia',
    ),

    // --- Inactive ---
    StudentModel(
      id: '7',
      name: 'Valentina Lagos',
      email: 'valentina@test.com',
      status: StudentStatus.inactive,
      lastAttendance: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  final List<Transaction> transactions = [
    Transaction(
      date: DateTime.now().subtract(const Duration(hours: 2)),
      studentId: '1',
      studentName: 'Camila Rodriguez',
      item: 'Clase de Bachata',
      amount: 5000,
      method: PaymentMethod.app,
      commission: 145,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      studentId: '4',
      studentName: 'Jose Ballesteros',
      item: 'Clase de Salsa',
      amount: 5000,
      method: PaymentMethod.app, // Changed to App to match user Profile
      commission: 145,
    ),
    Transaction(
      date: DateTime.now().subtract(const Duration(days: 8, hours: 2)),
      studentId: '99',
      studentName: 'Luisa M. (Privado)',
      item: 'Clase Privada',
      amount: 15000,
      method: PaymentMethod.transfer,
      commission: 0,
    ),
     Transaction(
      date: DateTime.now().subtract(const Duration(days: 9, hours: 1)),
      studentId: '88',
      studentName: 'Carlos R.',
      item: 'Clase de Bachata',
      amount: 5000,
      method: PaymentMethod.app,
      commission: 145,
    ),
     Transaction(
      date: DateTime.now().subtract(const Duration(days: 9, hours: 3)),
      studentId: '3',
      studentName: 'Andrea Soto',
      item: 'Pack 4 Clases',
      amount: 20000,
      method: PaymentMethod.app,
      commission: 580,
    ),
  ];

  // --- VENUES ---
  List<Map<String, String>> venues = [
    {
      'id': '1',
      'name': 'Gimnasio Central',
      'address': 'Av. Libertador 1234',
      'region': 'Metropolitana',
      'commune': 'Santiago',
    }
  ];

  // --- ACCESSORS for UI ---

  List<StudentModel> getSubscribers() => students.where((s) => s.status == StudentStatus.activePlan).toList();
  List<StudentModel> getDropIns() => students.where((s) => s.status == StudentStatus.dropIn).toList();
  List<StudentModel> getInactive() => students.where((s) => s.status == StudentStatus.inactive).toList();

  // --- CALCULATORS for Dashboard ---

  double getTotalRevenue() {
    return transactions.fold(0.0, (sum, t) => sum + t.amount);
  }
  
  // Commission logic could be complex, assuming fixed rate or per transaction
  double getTotalCommissions() {
    return transactions.fold(0.0, (sum, t) => sum + t.commission);
  }

  int getNewStudentsCount() {
    // Mock logic: return count of students created recently (simplified to just drop-ins count for demo)
    return getDropIns().length;
  }
  
  String getRetentionRate() {
    // Simple mock math: Active / Total
    int active = getSubscribers().length + getDropIns().length;
    int total = students.length;
    if (total == 0) return '0%';
    return '${((active / total) * 100).toInt()}%';
  }
}
