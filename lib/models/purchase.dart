import 'package:cloud_firestore/cloud_firestore.dart';

class Purchase {
  const Purchase({
    this.id,
    required this.date,
    required this.supplierName,
    required this.vehicleNumber,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.weight,
    required this.rate,
    required this.totalAmount,
    required this.paymentType,
    required this.notes,
    this.isDemo = false,
  });

  final String? id;
  final DateTime date;
  final String supplierName;
  final String vehicleNumber;
  final String itemId;
  final String itemName;
  final double quantity;
  final double weight;
  final double rate;
  final double totalAmount;
  final String paymentType;
  final String notes;
  final bool isDemo;

  Purchase copyWith({String? id, DateTime? date}) => Purchase(
    id: id,
    date: date ?? this.date,
    supplierName: supplierName,
    vehicleNumber: vehicleNumber,
    itemId: itemId,
    itemName: itemName,
    quantity: quantity,
    weight: weight,
    rate: rate,
    totalAmount: totalAmount,
    paymentType: paymentType,
    notes: notes,
    isDemo: isDemo,
  );

  factory Purchase.fromFirestore(String id, Map<String, dynamic> data) =>
      Purchase(
        id: id,
        date: (data['date']! as Timestamp).toDate(),
        supplierName: data['supplierName']! as String,
        vehicleNumber: data['vehicleNumber']! as String,
        itemId: data['itemId']! as String,
        itemName: data['itemName']! as String,
        quantity: (data['quantity']! as num).toDouble(),
        weight: (data['weight']! as num).toDouble(),
        rate: (data['rate']! as num).toDouble(),
        totalAmount: (data['totalAmount']! as num).toDouble(),
        paymentType: data['paymentType']! as String,
        notes: (data['notes'] as String?) ?? '',
        isDemo: (data['isDemo'] as bool?) ?? false,
      );

  Map<String, Object?> toFirestore() => {
    'date': Timestamp.fromDate(date),
    'supplierName': supplierName,
    'vehicleNumber': vehicleNumber,
    'itemId': itemId,
    'itemName': itemName,
    'quantity': quantity,
    'weight': weight,
    'rate': rate,
    'totalAmount': totalAmount,
    'paymentType': paymentType,
    'notes': notes,
    'isDemo': isDemo,
  };
}
