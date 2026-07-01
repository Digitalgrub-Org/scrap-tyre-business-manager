class Item {
  const Item({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.lowStockThreshold,
  });

  final String? id;
  final String name;
  final String category;
  final String unit;
  final double lowStockThreshold;

  factory Item.fromFirestore(String id, Map<String, dynamic> data) => Item(
    id: id,
    name: data['name']! as String,
    category: data['category']! as String,
    unit: data['unit']! as String,
    lowStockThreshold: (data['lowStockThreshold']! as num).toDouble(),
  );

  Map<String, Object?> toFirestore() => {
    'name': name,
    'category': category,
    'unit': unit,
    'lowStockThreshold': lowStockThreshold,
  };
}
