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

  final String itemId;
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
}
