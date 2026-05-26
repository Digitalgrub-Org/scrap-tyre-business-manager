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
  });

  final int? id;
  final DateTime date;
  final String customerName;
  final int itemId;
  final String itemName;
  final double quantity;
  final double weight;
  final double rate;
  final double totalAmount;
  final double transportCharges;
  final String paymentStatus;
  final String notes;

  Sale copyWith({int? id, DateTime? date}) => Sale(
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
  );

  factory Sale.fromMap(Map<String, Object?> map) => Sale(
    id: map['id'] as int?,
    date: DateTime.parse(map['date']! as String),
    customerName: map['customer_name']! as String,
    itemId: map['item_id']! as int,
    itemName: map['item_name']! as String,
    quantity: (map['quantity']! as num).toDouble(),
    weight: (map['weight']! as num).toDouble(),
    rate: (map['rate']! as num).toDouble(),
    totalAmount: (map['total_amount']! as num).toDouble(),
    transportCharges: (map['transport_charges']! as num).toDouble(),
    paymentStatus: map['payment_status']! as String,
    notes: (map['notes'] as String?) ?? '',
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'date': date.toIso8601String(),
    'customer_name': customerName,
    'item_id': itemId,
    'quantity': quantity,
    'weight': weight,
    'rate': rate,
    'total_amount': totalAmount,
    'transport_charges': transportCharges,
    'payment_status': paymentStatus,
    'notes': notes,
  };
}
