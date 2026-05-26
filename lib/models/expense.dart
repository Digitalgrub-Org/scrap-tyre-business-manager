class Expense {
  const Expense({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.notes,
  });

  final int? id;
  final DateTime date;
  final String type;
  final double amount;
  final String notes;

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map['id'] as int?,
    date: DateTime.parse(map['date']! as String),
    type: map['type']! as String,
    amount: (map['amount']! as num).toDouble(),
    notes: (map['notes'] as String?) ?? '',
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'date': date.toIso8601String(),
    'type': type,
    'amount': amount,
    'notes': notes,
  };
}
