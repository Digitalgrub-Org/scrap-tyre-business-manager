class StockEntry {
  const StockEntry({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.lowStockThreshold,
    required this.availableQuantity,
    required this.availableWeight,
    required this.averagePurchaseRate,
    required this.totalStockValue,
  });

  final int itemId;
  final String itemName;
  final String category;
  final String unit;
  final double lowStockThreshold;
  final double availableQuantity;
  final double availableWeight;
  final double averagePurchaseRate;
  final double totalStockValue;

  bool get isLowStock => unit == 'KG'
      ? availableWeight <= lowStockThreshold
      : availableQuantity <= lowStockThreshold;

  factory StockEntry.fromMap(Map<String, Object?> map) => StockEntry(
    itemId: map['item_id']! as int,
    itemName: map['item_name']! as String,
    category: map['category']! as String,
    unit: map['unit']! as String,
    lowStockThreshold: (map['low_stock_threshold']! as num).toDouble(),
    availableQuantity: (map['available_quantity']! as num).toDouble(),
    availableWeight: (map['available_weight']! as num).toDouble(),
    averagePurchaseRate: (map['average_purchase_rate']! as num).toDouble(),
    totalStockValue: (map['total_stock_value']! as num).toDouble(),
  );
}
