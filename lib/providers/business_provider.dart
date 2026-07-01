import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/business_summary.dart';
import '../models/business_profile.dart';
import '../models/expense.dart';
import '../models/item.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/stock_entry.dart';
import '../services/business_calculator.dart';
import '../services/business_repository.dart';

/// Holds the signed-in user's business data. Listens to auth state so that
/// signing in, signing out, or switching accounts automatically re-points to
/// the right user's data with no app restart required.
class BusinessProvider extends ChangeNotifier {
  BusinessProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  BusinessRepository? _repository;
  StreamSubscription<User?>? _authSub;
  String? _uid;

  bool isLoading = true;
  String? error;
  List<Item> items = [];
  List<Purchase> purchases = [];
  List<Sale> sales = [];
  List<Expense> expenses = [];
  List<StockEntry> stock = [];
  BusinessProfile profile = BusinessProfile.empty();
  bool hasCompletedOnboarding = false;
  bool hasDemoData = false;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user?.uid == _uid) return;
    _uid = user?.uid;
    if (user == null) {
      _repository = null;
      _resetState();
      notifyListeners();
      return;
    }
    final repository = BusinessRepository(uid: user.uid);
    _repository = repository;
    isLoading = true;
    notifyListeners();
    try {
      await repository.ensureSeeded();
    } catch (exception) {
      error = 'Unable to set up your data: $exception';
      isLoading = false;
      notifyListeners();
      return;
    }
    await refresh();
  }

  void _resetState() {
    items = [];
    purchases = [];
    sales = [];
    expenses = [];
    stock = [];
    profile = BusinessProfile.empty();
    hasCompletedOnboarding = false;
    hasDemoData = false;
    error = null;
    isLoading = false;
  }

  Future<void> refresh({bool showLoading = false}) async {
    final repository = _repository;
    if (repository == null) return;
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final loaded = await Future.wait([
        repository.getItems(),
        repository.getPurchases(),
        repository.getSales(),
        repository.getExpenses(),
        repository.getBusinessProfile(),
        repository.hasCompletedOnboarding(),
      ]);
      items = loaded[0] as List<Item>;
      purchases = loaded[1] as List<Purchase>;
      sales = loaded[2] as List<Sale>;
      expenses = loaded[3] as List<Expense>;
      profile = loaded[4] as BusinessProfile;
      hasCompletedOnboarding = loaded[5] as bool;
      stock = BusinessCalculator.computeStock(
        items: items,
        purchases: purchases,
        sales: sales,
      );
      hasDemoData =
          purchases.any((p) => p.isDemo) ||
          sales.any((s) => s.isDemo) ||
          expenses.any((e) => e.isDemo);
      error = null;
    } catch (exception) {
      error = 'Unable to load your business data: $exception';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  BusinessSummary get todaySummary {
    final today = DateTime.now();
    return summaryFor(DateTimeRange(start: today, end: today));
  }

  BusinessSummary summaryFor(DateTimeRange? range) =>
      BusinessCalculator.summarize(
        purchases: purchases,
        sales: sales,
        expenses: expenses,
        start: range?.start,
        end: range?.end,
      );

  List<DailyTrend> get trends => BusinessCalculator.trends(
    purchases: purchases,
    sales: sales,
    expenses: expenses,
  );

  double get stockValue =>
      stock.fold(0, (total, entry) => total + entry.totalStockValue);

  double get stockWeight =>
      stock.fold(0, (total, entry) => total + entry.availableWeight);

  double get stockQuantity =>
      stock.fold(0, (total, entry) => total + entry.availableQuantity);

  List<Purchase> purchasesIn(DateTimeRange? range) =>
      purchases.where((entry) => _inRange(entry.date, range)).toList();

  List<Sale> salesIn(DateTimeRange? range) =>
      sales.where((entry) => _inRange(entry.date, range)).toList();

  List<Expense> expensesIn(DateTimeRange? range) =>
      expenses.where((entry) => _inRange(entry.date, range)).toList();

  Future<String?> savePurchase(Purchase purchase) async {
    final validationError = _purchaseChangeError(
      replacement: purchase,
      removingId: purchase.id,
    );
    if (validationError != null) return validationError;
    await _repository!.savePurchase(purchase);
    await refresh();
    return null;
  }

  Future<String?> deletePurchase(Purchase purchase) async {
    if (purchase.id == null) return null;
    final validationError = _purchaseChangeError(removingId: purchase.id);
    if (validationError != null) return validationError;
    await _repository!.deletePurchase(purchase.id!);
    await refresh();
    return null;
  }

  Future<String?> saveSale(Sale sale) async {
    final available = stock
        .where((entry) => entry.itemId == sale.itemId)
        .cast<StockEntry?>()
        .firstOrNull;
    var availableQuantity = available?.availableQuantity ?? 0;
    var availableWeight = available?.availableWeight ?? 0;
    if (sale.id != null) {
      final original = sales.where((entry) => entry.id == sale.id).firstOrNull;
      if (original != null && original.itemId == sale.itemId) {
        availableQuantity += original.quantity;
        availableWeight += original.weight;
      }
    }
    if (sale.quantity > availableQuantity && sale.quantity > 0) {
      return 'Only ${availableQuantity.toStringAsFixed(2)} quantity is available.';
    }
    if (sale.weight > availableWeight) {
      return 'Only ${availableWeight.toStringAsFixed(2)} kg is available.';
    }
    await _repository!.saveSale(sale);
    await refresh();
    return null;
  }

  Future<void> deleteSale(Sale sale) async {
    if (sale.id == null) return;
    await _repository!.deleteSale(sale.id!);
    await refresh();
  }

  Future<void> saveExpense(Expense expense) async {
    await _repository!.saveExpense(expense);
    await refresh();
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await _repository!.deleteExpense(expense.id!);
    await refresh();
  }

  Future<void> completeOnboarding() async {
    await _repository!.completeOnboarding();
    hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> saveProfile(BusinessProfile updatedProfile) async {
    await _repository!.saveBusinessProfile(updatedProfile);
    profile = updatedProfile;
    notifyListeners();
  }

  Future<void> clearDemoData() async {
    await _repository!.clearDemoData();
    await refresh();
  }

  bool _inRange(DateTime date, DateTimeRange? range) {
    if (range == null) return true;
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  String? _purchaseChangeError({Purchase? replacement, String? removingId}) {
    final simulatedPurchases = [
      ...purchases.where((entry) => entry.id != removingId),
      ?replacement,
    ];
    for (final sale in sales) {
      final purchasedQuantity = simulatedPurchases
          .where((entry) => entry.itemId == sale.itemId)
          .fold<double>(0, (total, entry) => total + entry.quantity);
      final purchasedWeight = simulatedPurchases
          .where((entry) => entry.itemId == sale.itemId)
          .fold<double>(0, (total, entry) => total + entry.weight);
      final soldQuantity = sales
          .where((entry) => entry.itemId == sale.itemId)
          .fold<double>(0, (total, entry) => total + entry.quantity);
      final soldWeight = sales
          .where((entry) => entry.itemId == sale.itemId)
          .fold<double>(0, (total, entry) => total + entry.weight);
      if (soldQuantity > purchasedQuantity || soldWeight > purchasedWeight) {
        return 'This change would leave ${sale.itemName} below recorded sales. '
            'Update sales first.';
      }
    }
    return null;
  }
}
