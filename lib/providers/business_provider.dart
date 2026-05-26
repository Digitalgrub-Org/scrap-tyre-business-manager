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

class BusinessProvider extends ChangeNotifier {
  BusinessProvider({BusinessRepository? repository})
    : _repository = repository ?? BusinessRepository();

  final BusinessRepository _repository;

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

  Future<void> initialize() async {
    await refresh(showLoading: true);
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final loaded = await Future.wait([
        _repository.getItems(),
        _repository.getPurchases(),
        _repository.getSales(),
        _repository.getExpenses(),
        _repository.getStock(),
        _repository.getBusinessProfile(),
        _repository.hasCompletedOnboarding(),
        _repository.hasDemoData(),
      ]);
      items = loaded[0] as List<Item>;
      purchases = loaded[1] as List<Purchase>;
      sales = loaded[2] as List<Sale>;
      expenses = loaded[3] as List<Expense>;
      stock = loaded[4] as List<StockEntry>;
      profile = loaded[5] as BusinessProfile;
      hasCompletedOnboarding = loaded[6] as bool;
      hasDemoData = loaded[7] as bool;
      error = null;
    } catch (exception) {
      error = 'Unable to load local business data: $exception';
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
    await _repository.savePurchase(purchase);
    await refresh();
    return null;
  }

  Future<String?> deletePurchase(Purchase purchase) async {
    if (purchase.id == null) return null;
    final validationError = _purchaseChangeError(removingId: purchase.id);
    if (validationError != null) return validationError;
    await _repository.deletePurchase(purchase.id!);
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
    await _repository.saveSale(sale);
    await refresh();
    return null;
  }

  Future<void> deleteSale(Sale sale) async {
    if (sale.id == null) return;
    await _repository.deleteSale(sale.id!);
    await refresh();
  }

  Future<void> saveExpense(Expense expense) async {
    await _repository.saveExpense(expense);
    await refresh();
  }

  Future<void> deleteExpense(Expense expense) async {
    if (expense.id == null) return;
    await _repository.deleteExpense(expense.id!);
    await refresh();
  }

  Future<void> completeOnboarding() async {
    await _repository.completeOnboarding();
    hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> saveProfile(BusinessProfile updatedProfile) async {
    await _repository.saveBusinessProfile(updatedProfile);
    profile = updatedProfile;
    notifyListeners();
  }

  Future<void> clearDemoData() async {
    await _repository.clearDemoData();
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

  String? _purchaseChangeError({Purchase? replacement, int? removingId}) {
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
