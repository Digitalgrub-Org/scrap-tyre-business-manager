class Item {
  const Item({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.lowStockThreshold,
  });

  final int? id;
  final String name;
  final String category;
  final String unit;
  final double lowStockThreshold;

  factory Item.fromMap(Map<String, Object?> map) => Item(
    id: map['id'] as int?,
    name: map['name']! as String,
    category: map['category']! as String,
    unit: map['unit']! as String,
    lowStockThreshold: (map['low_stock_threshold']! as num).toDouble(),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'category': category,
    'unit': unit,
    'low_stock_threshold': lowStockThreshold,
  };
}
