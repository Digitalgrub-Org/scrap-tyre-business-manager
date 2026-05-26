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
  });

  final int? id;
  final DateTime date;
  final String supplierName;
  final String vehicleNumber;
  final int itemId;
  final String itemName;
  final double quantity;
  final double weight;
  final double rate;
  final double totalAmount;
  final String paymentType;
  final String notes;

  Purchase copyWith({int? id, DateTime? date}) => Purchase(
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
  );

  factory Purchase.fromMap(Map<String, Object?> map) => Purchase(
    id: map['id'] as int?,
    date: DateTime.parse(map['date']! as String),
    supplierName: map['supplier_name']! as String,
    vehicleNumber: map['vehicle_number']! as String,
    itemId: map['item_id']! as int,
    itemName: map['item_name']! as String,
    quantity: (map['quantity']! as num).toDouble(),
    weight: (map['weight']! as num).toDouble(),
    rate: (map['rate']! as num).toDouble(),
    totalAmount: (map['total_amount']! as num).toDouble(),
    paymentType: map['payment_type']! as String,
    notes: (map['notes'] as String?) ?? '',
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'date': date.toIso8601String(),
    'supplier_name': supplierName,
    'vehicle_number': vehicleNumber,
    'item_id': itemId,
    'quantity': quantity,
    'weight': weight,
    'rate': rate,
    'total_amount': totalAmount,
    'payment_type': paymentType,
    'notes': notes,
  };
}
