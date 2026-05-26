import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/business_profile.dart';
import '../models/expense.dart';
import '../models/item.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/stock_entry.dart';

class BusinessRepository {
  BusinessRepository({AppDatabase? database})
    : _source = database ?? AppDatabase.instance;

  final AppDatabase _source;

  Future<List<Item>> getItems() async {
    final db = await _source.database;
    final rows = await db.query('items', orderBy: 'category, name');
    return rows.map(Item.fromMap).toList();
  }

  Future<List<Purchase>> getPurchases() async {
    final db = await _source.database;
    final rows = await db.rawQuery('''
      SELECT p.*, i.name AS item_name FROM purchases p
      INNER JOIN items i ON i.id = p.item_id
      ORDER BY p.date DESC, p.id DESC
    ''');
    return rows.map(Purchase.fromMap).toList();
  }

  Future<List<Sale>> getSales() async {
    final db = await _source.database;
    final rows = await db.rawQuery('''
      SELECT s.*, i.name AS item_name FROM sales s
      INNER JOIN items i ON i.id = s.item_id
      ORDER BY s.date DESC, s.id DESC
    ''');
    return rows.map(Sale.fromMap).toList();
  }

  Future<List<Expense>> getExpenses() async {
    final db = await _source.database;
    final rows = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<StockEntry>> getStock() async {
    final db = await _source.database;
    final rows = await db.rawQuery('''
      SELECT s.*, i.name AS item_name, i.category, i.unit, i.low_stock_threshold
      FROM stock s INNER JOIN items i ON i.id = s.item_id
      ORDER BY i.category, i.name
    ''');
    return rows.map(StockEntry.fromMap).toList();
  }

  Future<BusinessProfile> getBusinessProfile() async {
    final db = await _source.database;
    final rows = await db.query('business_profile', where: 'id = 1');
    return rows.isEmpty
        ? BusinessProfile.empty()
        : BusinessProfile.fromMap(rows.first);
  }

  Future<bool> hasCompletedOnboarding() async {
    final db = await _source.database;
    final rows = await db.query(
      'app_preferences',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['onboarding_completed'],
    );
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<bool> hasDemoData() async {
    final db = await _source.database;
    final result = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM purchases WHERE is_demo = 1) +
        (SELECT COUNT(*) FROM sales WHERE is_demo = 1) +
        (SELECT COUNT(*) FROM expenses WHERE is_demo = 1) AS count
    ''');
    return (result.first['count']! as num).toInt() > 0;
  }

  Future<void> completeOnboarding() async {
    final db = await _source.database;
    await db.update(
      'app_preferences',
      {'value': '1'},
      where: 'key = ?',
      whereArgs: ['onboarding_completed'],
    );
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    final db = await _source.database;
    await db.insert(
      'business_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearDemoData() async {
    final db = await _source.database;
    await db.transaction((txn) async {
      final demoPurchases = await txn.query(
        'purchases',
        columns: ['id'],
        where: 'is_demo = 1',
      );
      final demoSales = await txn.query(
        'sales',
        columns: ['id'],
        where: 'is_demo = 1',
      );
      for (final row in demoPurchases) {
        await txn.delete(
          'payments',
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['purchase', row['id']],
        );
      }
      for (final row in demoSales) {
        await txn.delete(
          'payments',
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['sale', row['id']],
        );
      }
      await txn.delete('purchases', where: 'is_demo = 1');
      await txn.delete('sales', where: 'is_demo = 1');
      await txn.delete('expenses', where: 'is_demo = 1');
      await _source.rebuildStock(txn);
    });
  }

  Future<void> savePurchase(Purchase purchase) async {
    final db = await _source.database;
    await db.transaction((txn) async {
      final values = {
        ...purchase.toMap()..remove('id'),
        'created_at': DateTime.now().toIso8601String(),
      };
      final referenceId = purchase.id == null
          ? await txn.insert('purchases', values)
          : purchase.id!;
      if (purchase.id != null) {
        await txn.update(
          'purchases',
          values,
          where: 'id = ?',
          whereArgs: [purchase.id],
        );
      }
      await _addSupplier(txn, purchase.supplierName);
      await _replacePayment(
        txn,
        referenceType: 'purchase',
        referenceId: referenceId,
        amount: purchase.totalAmount,
        type: purchase.paymentType,
        status: purchase.paymentType == 'Credit' ? 'Pending' : 'Paid',
        date: purchase.date,
      );
      await _source.rebuildStock(txn);
    });
  }

  Future<void> deletePurchase(int id) async {
    final db = await _source.database;
    await db.transaction((txn) async {
      await txn.delete(
        'payments',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['purchase', id],
      );
      await txn.delete('purchases', where: 'id = ?', whereArgs: [id]);
      await _source.rebuildStock(txn);
    });
  }

  Future<void> saveSale(Sale sale) async {
    final db = await _source.database;
    await db.transaction((txn) async {
      final values = {
        ...sale.toMap()..remove('id'),
        'created_at': DateTime.now().toIso8601String(),
      };
      final referenceId = sale.id == null
          ? await txn.insert('sales', values)
          : sale.id!;
      if (sale.id != null) {
        await txn.update(
          'sales',
          values,
          where: 'id = ?',
          whereArgs: [sale.id],
        );
      }
      await _addCustomer(txn, sale.customerName);
      await _replacePayment(
        txn,
        referenceType: 'sale',
        referenceId: referenceId,
        amount: sale.totalAmount,
        type: 'Receivable',
        status: sale.paymentStatus,
        date: sale.date,
      );
      await _source.rebuildStock(txn);
    });
  }

  Future<void> deleteSale(int id) async {
    final db = await _source.database;
    await db.transaction((txn) async {
      await txn.delete(
        'payments',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['sale', id],
      );
      await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
      await _source.rebuildStock(txn);
    });
  }

  Future<void> saveExpense(Expense expense) async {
    final db = await _source.database;
    final values = {
      ...expense.toMap()..remove('id'),
      'created_at': DateTime.now().toIso8601String(),
    };
    if (expense.id == null) {
      await db.insert('expenses', values);
    } else {
      await db.update(
        'expenses',
        values,
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    }
  }

  Future<void> deleteExpense(int id) async {
    final db = await _source.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _addSupplier(DatabaseExecutor txn, String name) async {
    await txn.insert('suppliers', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _addCustomer(DatabaseExecutor txn, String name) async {
    await txn.insert('customers', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _replacePayment(
    DatabaseExecutor txn, {
    required String referenceType,
    required int referenceId,
    required double amount,
    required String type,
    required String status,
    required DateTime date,
  }) async {
    await txn.delete(
      'payments',
      where: 'reference_type = ? AND reference_id = ?',
      whereArgs: [referenceType, referenceId],
    );
    await txn.insert('payments', {
      'reference_type': referenceType,
      'reference_id': referenceId,
      'amount': amount,
      'payment_type': type,
      'status': status,
      'date': date.toIso8601String(),
      'notes': '',
    });
  }
}
