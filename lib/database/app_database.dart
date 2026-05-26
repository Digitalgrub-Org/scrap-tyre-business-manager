import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../constants/item_catalog.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _databaseName = 'scrap_tyre_manager.db';
  static const _version = 2;

  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final basePath = await getDatabasesPath();
    return openDatabase(
      path.join(basePath, _databaseName),
      version: _version,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        low_stock_threshold REAL NOT NULL DEFAULT 5
      )
    ''');
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        vehicle_number TEXT NOT NULL,
        item_id INTEGER NOT NULL REFERENCES items(id),
        quantity REAL NOT NULL,
        weight REAL NOT NULL,
        rate REAL NOT NULL,
        total_amount REAL NOT NULL,
        payment_type TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        is_demo INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        item_id INTEGER NOT NULL REFERENCES items(id),
        quantity REAL NOT NULL,
        weight REAL NOT NULL,
        rate REAL NOT NULL,
        total_amount REAL NOT NULL,
        transport_charges REAL NOT NULL DEFAULT 0,
        payment_status TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        is_demo INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        is_demo INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference_type TEXT NOT NULL,
        reference_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_type TEXT NOT NULL,
        status TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE stock (
        item_id INTEGER PRIMARY KEY REFERENCES items(id),
        available_quantity REAL NOT NULL DEFAULT 0,
        available_weight REAL NOT NULL DEFAULT 0,
        average_purchase_rate REAL NOT NULL DEFAULT 0,
        total_stock_value REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
    await _createSettingsTables(db);

    for (final seed in ItemCatalog.seeds) {
      await db.insert('items', {
        'name': seed.name,
        'category': seed.category,
        'unit': seed.unit,
        'low_stock_threshold': seed.lowStockThreshold,
      });
    }
    await _seedSampleBusinessData(db);
    await rebuildStock(db);
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE purchases ADD COLUMN is_demo INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE sales ADD COLUMN is_demo INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE expenses ADD COLUMN is_demo INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE purchases SET is_demo = 1
        WHERE id IN (1, 2, 3)
          AND supplier_name IN (
            'Sri Murugan Tyres',
            'Kongu Scrap Supply',
            'Raja Auto Works'
          )
      ''');
      await db.execute('''
        UPDATE sales SET is_demo = 1
        WHERE id IN (1, 2, 3)
          AND customer_name IN ('Ganesh Recyclers', 'Velan Rubber Works')
      ''');
      await db.execute('''
        UPDATE expenses SET is_demo = 1
        WHERE id IN (1, 2) AND type IN ('Labour', 'Miscellaneous')
      ''');
      await _createSettingsTables(db);
    }
  }

  Future<void> _createSettingsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS business_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        business_name TEXT NOT NULL DEFAULT '',
        owner_name TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        tax_id TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.insert('app_preferences', {
      'key': 'onboarding_completed',
      'value': '0',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('business_profile', {
      'id': 1,
      'business_name': '',
      'owner_name': '',
      'phone': '',
      'address': '',
      'tax_id': '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _seedSampleBusinessData(Database db) async {
    final rows = await db.query('items');
    final itemIds = {
      for (final row in rows) row['name']! as String: row['id']! as int,
    };
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    String on(int daysBefore) =>
        dateOnly.subtract(Duration(days: daysBefore)).toIso8601String();
    final created = DateTime.now().toIso8601String();

    await db.insert('purchases', {
      'date': on(0),
      'supplier_name': 'Sri Murugan Tyres',
      'vehicle_number': 'TN 33 AB 4432',
      'item_id': itemIds['Car Tyre'],
      'quantity': 28.0,
      'weight': 256.0,
      'rate': 34.0,
      'total_amount': 8704.0,
      'payment_type': 'UPI',
      'notes': 'Morning load',
      'is_demo': 1,
      'created_at': created,
    });
    await db.insert('purchases', {
      'date': on(0),
      'supplier_name': 'Kongu Scrap Supply',
      'vehicle_number': 'TN 39 CX 1281',
      'item_id': itemIds['Nylon Tyre KG'],
      'quantity': 0.0,
      'weight': 410.0,
      'rate': 31.0,
      'total_amount': 12710.0,
      'payment_type': 'Credit',
      'notes': '',
      'is_demo': 1,
      'created_at': created,
    });
    await db.insert('purchases', {
      'date': on(2),
      'supplier_name': 'Raja Auto Works',
      'vehicle_number': 'TN 38 M 8870',
      'item_id': itemIds['Tube KG'],
      'quantity': 0.0,
      'weight': 175.0,
      'rate': 48.0,
      'total_amount': 8400.0,
      'payment_type': 'Cash',
      'notes': '',
      'is_demo': 1,
      'created_at': created,
    });
    await db.insert('sales', {
      'date': on(0),
      'customer_name': 'Ganesh Recyclers',
      'item_id': itemIds['Car Tyre'],
      'quantity': 12.0,
      'weight': 108.0,
      'rate': 47.0,
      'total_amount': 5076.0,
      'transport_charges': 350.0,
      'payment_status': 'Paid',
      'notes': '',
      'is_demo': 1,
      'created_at': created,
    });
    await db.insert('sales', {
      'date': on(0),
      'customer_name': 'Velan Rubber Works',
      'item_id': itemIds['Nylon Tyre KG'],
      'quantity': 0.0,
      'weight': 140.0,
      'rate': 44.0,
      'total_amount': 6160.0,
      'transport_charges': 450.0,
      'payment_status': 'Partial',
      'notes': 'Balance expected Friday',
      'is_demo': 1,
      'created_at': created,
    });
    await db.insert('sales', {
      'date': on(1),
      'customer_name': 'Ganesh Recyclers',
      'item_id': itemIds['Tube KG'],
      'quantity': 0.0,
      'weight': 65.0,
      'rate': 64.0,
      'total_amount': 4160.0,
      'transport_charges': 0.0,
      'payment_status': 'Pending',
      'notes': '',
      'is_demo': 1,
      'created_at': created,
    });
    await db.insert('expenses', {
      'date': on(0),
      'type': 'Labour',
      'amount': 850.0,
      'notes': 'Sorting and loading',
      'is_demo': 1,
      'created_at': created,
    });
    await db.insert('expenses', {
      'date': on(1),
      'type': 'Miscellaneous',
      'amount': 240.0,
      'notes': 'Tea and packing rope',
      'is_demo': 1,
      'created_at': created,
    });
  }

  Future<void> rebuildStock(DatabaseExecutor executor) async {
    final now = DateTime.now().toIso8601String();
    final items = await executor.query('items');
    await executor.delete('stock');
    for (final item in items) {
      final itemId = item['id']! as int;
      final purchased = await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(quantity), 0) AS quantity,
          COALESCE(SUM(weight), 0) AS weight,
          COALESCE(SUM(total_amount), 0) AS amount
        FROM purchases WHERE item_id = ?
        ''',
        [itemId],
      );
      final sold = await executor.rawQuery(
        '''
        SELECT COALESCE(SUM(quantity), 0) AS quantity,
          COALESCE(SUM(weight), 0) AS weight
        FROM sales WHERE item_id = ?
        ''',
        [itemId],
      );
      final purchaseWeight = (purchased.first['weight']! as num).toDouble();
      final purchaseAmount = (purchased.first['amount']! as num).toDouble();
      final availableQuantity =
          (purchased.first['quantity']! as num).toDouble() -
          (sold.first['quantity']! as num).toDouble();
      final availableWeight =
          purchaseWeight - (sold.first['weight']! as num).toDouble();
      final averageRate = purchaseWeight == 0
          ? 0.0
          : purchaseAmount / purchaseWeight;
      await executor.insert('stock', {
        'item_id': itemId,
        'available_quantity': availableQuantity,
        'available_weight': availableWeight,
        'average_purchase_rate': averageRate,
        'total_stock_value': availableWeight * averageRate,
        'updated_at': now,
      });
    }
  }
}
