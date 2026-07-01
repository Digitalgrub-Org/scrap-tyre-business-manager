import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  const Sale({
    this.id,
    required this.date,
    required this.customerName,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.weight,
    required this.rate,
    required this.totalAmount,
    required this.transportCharges,
    required this.paymentStatus,
    required this.notes,
    this.isDemo = false,
  });

  final String? id;
  final DateTime date;
  final String customerName;
  final String itemId;
  final String itemName;
  final double quantity;
  final double weight;
  final double rate;
  final double totalAmount;
  final double transportCharges;
  final String paymentStatus;
  final String notes;
  final bool isDemo;

  Sale copyWith({String? id, DateTime? date}) => Sale(
    id: id,
    date: date ?? this.date,
    customerName: customerName,
    itemId: itemId,
    itemName: itemName,
    quantity: quantity,
    weight: weight,
    rate: rate,
    totalAmount: totalAmount,
    transportCharges: transportCharges,
    paymentStatus: paymentStatus,
    notes: notes,
    isDemo: isDemo,
  );

  factory Sale.fromFirestore(String id, Map<String, dynamic> data) => Sale(
    id: id,
    date: (data['date']! as Timestamp).toDate(),
    customerName: data['customerName']! as String,
    itemId: data['itemId']! as String,
    itemName: data['itemName']! as String,
    quantity: (data['quantity']! as num).toDouble(),
    weight: (data['weight']! as num).toDouble(),
    rate: (data['rate']! as num).toDouble(),
    totalAmount: (data['totalAmount']! as num).toDouble(),
    transportCharges: (data['transportCharges']! as num).toDouble(),
    paymentStatus: data['paymentStatus']! as String,
    notes: (data['notes'] as String?) ?? '',
    isDemo: (data['isDemo'] as bool?) ?? false,
  );

  Map<String, Object?> toFirestore() => {
    'date': Timestamp.fromDate(date),
    'customerName': customerName,
    'itemId': itemId,
    'itemName': itemName,
    'quantity': quantity,
    'weight': weight,
    'rate': rate,
    'totalAmount': totalAmount,
    'transportCharges': transportCharges,
    'paymentStatus': paymentStatus,
    'notes': notes,
    'isDemo': isDemo,
  };
}
