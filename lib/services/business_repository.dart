import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/item_catalog.dart';
import '../models/business_profile.dart';
import '../models/expense.dart';
import '../models/item.dart';
import '../models/purchase.dart';
import '../models/sale.dart';

/// Firestore-backed repository, scoped to one user's data under
/// `users/{uid}/...`. Each signed-in identity (email, Google, or guest) gets
/// its own isolated set of collections.
class BusinessRepository {
  BusinessRepository({required String uid, FirebaseFirestore? firestore})
    : _uid = uid,
      _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);
  CollectionReference<Map<String, dynamic>> get _items =>
      _userDoc.collection('items');
  CollectionReference<Map<String, dynamic>> get _suppliers =>
      _userDoc.collection('suppliers');
  CollectionReference<Map<String, dynamic>> get _customers =>
      _userDoc.collection('customers');
  CollectionReference<Map<String, dynamic>> get _purchases =>
      _userDoc.collection('purchases');
  CollectionReference<Map<String, dynamic>> get _sales =>
      _userDoc.collection('sales');
  CollectionReference<Map<String, dynamic>> get _expenses =>
      _userDoc.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _payments =>
      _userDoc.collection('payments');

  /// Seeds the item catalog and sample demo data the first time this user is
  /// seen (an empty `items` collection). Safe to call on every sign in.
  Future<void> ensureSeeded() async {
    final existing = await _items.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    final itemIdByName = <String, String>{};
    for (final seed in ItemCatalog.seeds) {
      final ref = _items.doc();
      itemIdByName[seed.name] = ref.id;
      batch.set(
        ref,
        Item(
          name: seed.name,
          category: seed.category,
          unit: seed.unit,
          lowStockThreshold: seed.lowStockThreshold,
        ).toFirestore(),
      );
    }
    batch.set(_userDoc, {
      'onboardingCompleted': false,
    }, SetOptions(merge: true));
    await batch.commit();
    await _seedSampleBusinessData(itemIdByName);
  }

  Future<void> _seedSampleBusinessData(Map<String, String> itemIdByName) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    DateTime on(int daysBefore) => dateOnly.subtract(Duration(days: daysBefore));

    final batch = _db.batch();
    void purchase({
      required int daysBefore,
      required String supplierName,
      required String vehicleNumber,
      required String itemName,
      required double quantity,
      required double weight,
      required double rate,
      required double totalAmount,
      required String paymentType,
      String notes = '',
    }) {
      final ref = _purchases.doc();
      batch.set(ref, {
        ...Purchase(
          date: on(daysBefore),
          supplierName: supplierName,
          vehicleNumber: vehicleNumber,
          itemId: itemIdByName[itemName]!,
          itemName: itemName,
          quantity: quantity,
          weight: weight,
          rate: rate,
          totalAmount: totalAmount,
          paymentType: paymentType,
          notes: notes,
          isDemo: true,
        ).toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_payments.doc('purchase_${ref.id}'), {
        'referenceType': 'purchase',
        'referenceId': ref.id,
        'amount': totalAmount,
        'paymentType': paymentType,
        'status': paymentType == 'Credit' ? 'Pending' : 'Paid',
        'date': Timestamp.fromDate(on(daysBefore)),
        'notes': '',
      });
    }

    void sale({
      required int daysBefore,
      required String customerName,
      required String itemName,
      required double quantity,
      required double weight,
      required double rate,
      required double totalAmount,
      required double transportCharges,
      required String paymentStatus,
      String notes = '',
    }) {
      final ref = _sales.doc();
      batch.set(ref, {
        ...Sale(
          date: on(daysBefore),
          customerName: customerName,
          itemId: itemIdByName[itemName]!,
          itemName: itemName,
          quantity: quantity,
          weight: weight,
          rate: rate,
          totalAmount: totalAmount,
          transportCharges: transportCharges,
          paymentStatus: paymentStatus,
          notes: notes,
          isDemo: true,
        ).toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_payments.doc('sale_${ref.id}'), {
        'referenceType': 'sale',
        'referenceId': ref.id,
        'amount': totalAmount,
        'paymentType': 'Receivable',
        'status': paymentStatus,
        'date': Timestamp.fromDate(on(daysBefore)),
        'notes': '',
      });
    }

    void expense({
      required int daysBefore,
      required String type,
      required double amount,
      String notes = '',
    }) {
      batch.set(_expenses.doc(), {
        ...Expense(
          date: on(daysBefore),
          type: type,
          amount: amount,
          notes: notes,
          isDemo: true,
        ).toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    purchase(
      daysBefore: 0,
      supplierName: 'Sri Murugan Tyres',
      vehicleNumber: 'TN 33 AB 4432',
      itemName: 'Car Tyre',
      quantity: 28,
      weight: 256,
      rate: 34,
      totalAmount: 8704,
      paymentType: 'UPI',
      notes: 'Morning load',
    );
    purchase(
      daysBefore: 0,
      supplierName: 'Kongu Scrap Supply',
      vehicleNumber: 'TN 39 CX 1281',
      itemName: 'Nylon Tyre KG',
      quantity: 0,
      weight: 410,
      rate: 31,
      totalAmount: 12710,
      paymentType: 'Credit',
    );
    purchase(
      daysBefore: 2,
      supplierName: 'Raja Auto Works',
      vehicleNumber: 'TN 38 M 8870',
      itemName: 'Tube KG',
      quantity: 0,
      weight: 175,
      rate: 48,
      totalAmount: 8400,
      paymentType: 'Cash',
    );
    sale(
      daysBefore: 0,
      customerName: 'Ganesh Recyclers',
      itemName: 'Car Tyre',
      quantity: 12,
      weight: 108,
      rate: 47,
      totalAmount: 5076,
      transportCharges: 350,
      paymentStatus: 'Paid',
    );
    sale(
      daysBefore: 0,
      customerName: 'Velan Rubber Works',
      itemName: 'Nylon Tyre KG',
      quantity: 0,
      weight: 140,
      rate: 44,
      totalAmount: 6160,
      transportCharges: 450,
      paymentStatus: 'Partial',
      notes: 'Balance expected Friday',
    );
    sale(
      daysBefore: 1,
      customerName: 'Ganesh Recyclers',
      itemName: 'Tube KG',
      quantity: 0,
      weight: 65,
      rate: 64,
      totalAmount: 4160,
      transportCharges: 0,
      paymentStatus: 'Pending',
    );
    expense(daysBefore: 0, type: 'Labour', amount: 850, notes: 'Sorting and loading');
    expense(
      daysBefore: 1,
      type: 'Miscellaneous',
      amount: 240,
      notes: 'Tea and packing rope',
    );

    await batch.commit();
  }

  Future<List<Item>> getItems() async {
    final snap = await _items.get();
    final items = snap.docs
        .map((d) => Item.fromFirestore(d.id, d.data()))
        .toList();
    items.sort((a, b) {
      final byCategory = a.category.compareTo(b.category);
      return byCategory != 0 ? byCategory : a.name.compareTo(b.name);
    });
    return items;
  }

  Future<List<Purchase>> getPurchases() async {
    final snap = await _purchases.orderBy('date', descending: true).get();
    return snap.docs
        .map((d) => Purchase.fromFirestore(d.id, d.data()))
        .toList();
  }

  Future<List<Sale>> getSales() async {
    final snap = await _sales.orderBy('date', descending: true).get();
    return snap.docs.map((d) => Sale.fromFirestore(d.id, d.data())).toList();
  }

  Future<List<Expense>> getExpenses() async {
    final snap = await _expenses.orderBy('date', descending: true).get();
    return snap.docs
        .map((d) => Expense.fromFirestore(d.id, d.data()))
        .toList();
  }

  Future<BusinessProfile> getBusinessProfile() async {
    final snap = await _userDoc.get();
    final data = snap.data();
    return data == null
        ? BusinessProfile.empty()
        : BusinessProfile.fromFirestore(data);
  }

  Future<bool> hasCompletedOnboarding() async {
    final snap = await _userDoc.get();
    return (snap.data()?['onboardingCompleted'] as bool?) ?? false;
  }

  Future<void> completeOnboarding() async {
    await _userDoc.set({
      'onboardingCompleted': true,
    }, SetOptions(merge: true));
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    await _userDoc.set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> clearDemoData() async {
    final batch = _db.batch();
    final demoPurchases = await _purchases.where('isDemo', isEqualTo: true).get();
    final demoSales = await _sales.where('isDemo', isEqualTo: true).get();
    final demoExpenses = await _expenses.where('isDemo', isEqualTo: true).get();
    for (final doc in demoPurchases.docs) {
      batch.delete(doc.reference);
      batch.delete(_payments.doc('purchase_${doc.id}'));
    }
    for (final doc in demoSales.docs) {
      batch.delete(doc.reference);
      batch.delete(_payments.doc('sale_${doc.id}'));
    }
    for (final doc in demoExpenses.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> savePurchase(Purchase purchase) async {
    final String referenceId;
    if (purchase.id == null) {
      final ref = _purchases.doc();
      referenceId = ref.id;
      await ref.set({
        ...purchase.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      referenceId = purchase.id!;
      await _purchases.doc(referenceId).update(purchase.toFirestore());
    }
    await _addParty(_suppliers, purchase.supplierName);
    await _replacePayment(
      referenceType: 'purchase',
      referenceId: referenceId,
      amount: purchase.totalAmount,
      type: purchase.paymentType,
      status: purchase.paymentType == 'Credit' ? 'Pending' : 'Paid',
      date: purchase.date,
    );
  }

  Future<void> deletePurchase(String id) async {
    await _payments.doc('purchase_$id').delete();
    await _purchases.doc(id).delete();
  }

  Future<void> saveSale(Sale sale) async {
    final String referenceId;
    if (sale.id == null) {
      final ref = _sales.doc();
      referenceId = ref.id;
      await ref.set({
        ...sale.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      referenceId = sale.id!;
      await _sales.doc(referenceId).update(sale.toFirestore());
    }
    await _addParty(_customers, sale.customerName);
    await _replacePayment(
      referenceType: 'sale',
      referenceId: referenceId,
      amount: sale.totalAmount,
      type: 'Receivable',
      status: sale.paymentStatus,
      date: sale.date,
    );
  }

  Future<void> deleteSale(String id) async {
    await _payments.doc('sale_$id').delete();
    await _sales.doc(id).delete();
  }

  Future<void> saveExpense(Expense expense) async {
    if (expense.id == null) {
      await _expenses.doc().set({
        ...expense.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _expenses.doc(expense.id).update(expense.toFirestore());
    }
  }

  Future<void> deleteExpense(String id) async {
    await _expenses.doc(id).delete();
  }

  Future<void> _addParty(
    CollectionReference<Map<String, dynamic>> collection,
    String name,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final ref = collection.doc(trimmed.replaceAll('/', '-'));
    final existing = await ref.get();
    if (existing.exists) return;
    await ref.set({'name': trimmed, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> _replacePayment({
    required String referenceType,
    required String referenceId,
    required double amount,
    required String type,
    required String status,
    required DateTime date,
  }) async {
    await _payments.doc('${referenceType}_$referenceId').set({
      'referenceType': referenceType,
      'referenceId': referenceId,
      'amount': amount,
      'paymentType': type,
      'status': status,
      'date': Timestamp.fromDate(date),
      'notes': '',
    });
  }
}
