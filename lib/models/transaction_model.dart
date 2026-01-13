import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { app, cash, transfer }

class Transaction {
  final DateTime date; // Changed to DateTime for proper sorting
  final String studentId;
  final String studentName; // Denormalized for simpler UI
  final String item;
  final double amount;
  final PaymentMethod method;
  final double commission;

  Transaction({
    required this.date,
    required this.studentId,
    required this.studentName,
    required this.item,
    required this.amount,
    required this.method,
    required this.commission,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'studentId': studentId,
      'studentName': studentName,
      'item': item,
      'amount': amount,
      'method': method.toString().split('.').last, // Store as string 'app', 'cash'
      'commission': commission,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      date: (map['date'] as Timestamp).toDate(),
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? 'Desconocido',
      item: map['item'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      method: PaymentMethod.values.firstWhere(
            (e) => e.toString().split('.').last == map['method'],
        orElse: () => PaymentMethod.cash,
      ),
      commission: (map['commission'] ?? 0).toDouble(),
    );
  }
}
