class ItemSeed {
  const ItemSeed({
    required this.name,
    required this.category,
    required this.unit,
    this.lowStockThreshold = 5,
  });

  final String name;
  final String category;
  final String unit;
  final double lowStockThreshold;
}

class ItemCatalog {
  ItemCatalog._();

  static const tyresAndTubes = [
    '2 Wheeler Tyre',
    'Tube',
    'Car Tyre',
    'Car Tube',
    '7.00-15 Tyre',
    '7.00-15 Tube',
    '7.00-16 Tyre',
    '7.00-16 Tube',
    '7.50-16 Tyre',
    '7.50-16 Tube',
    '8.25-16 Tyre',
    '8.25-16 Tube',
    '9.00-16 Tyre',
    '9.00-16 Tube',
    '9.20 Tyre',
    '9.20 Tube',
    '10.20 Tyre',
    '10.20 Tube',
    '11.20 Tyre',
    '11.20 Tube',
  ];

  static const rimSizes = ['12 Size', '13 Size', '14 Size', '16 Size'];

  static const weightCategories = [
    'Tube KG',
    'Radial Tyre KG',
    'Nylon Tyre KG',
    'Flap Weight KG',
  ];

  static const otherItems = ['OK Tube', 'OK Flap', 'Flap Piece'];

  static List<ItemSeed> get seeds => [
    ...tyresAndTubes.map(
      (name) => ItemSeed(name: name, category: 'Tyres & Tubes', unit: 'Nos'),
    ),
    ...rimSizes.map(
      (name) => ItemSeed(name: name, category: 'Rim Sizes', unit: 'Nos'),
    ),
    ...weightCategories.map(
      (name) => ItemSeed(
        name: name,
        category: 'Weight Categories',
        unit: 'KG',
        lowStockThreshold: 25,
      ),
    ),
    ...otherItems.map(
      (name) => ItemSeed(name: name, category: 'Other Items', unit: 'Nos'),
    ),
  ];
}
