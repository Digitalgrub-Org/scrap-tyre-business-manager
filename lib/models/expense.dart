import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  const Expense({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.notes,
    this.isDemo = false,
  });

  final String? id;
  final DateTime date;
  final String type;
  final double amount;
  final String notes;
  final bool isDemo;

  factory Expense.fromFirestore(String id, Map<String, dynamic> data) =>
      Expense(
        id: id,
        date: (data['date']! as Timestamp).toDate(),
        type: data['type']! as String,
        amount: (data['amount']! as num).toDouble(),
        notes: (data['notes'] as String?) ?? '',
        isDemo: (data['isDemo'] as bool?) ?? false,
      );

  Map<String, Object?> toFirestore() => {
    'date': Timestamp.fromDate(date),
    'type': type,
    'amount': amount,
    'notes': notes,
    'isDemo': isDemo,
  };
}
