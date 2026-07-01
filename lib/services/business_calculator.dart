import '../models/business_summary.dart';
import '../models/expense.dart';
import '../models/item.dart';
import '../models/purchase.dart';
import '../models/sale.dart';
import '../models/stock_entry.dart';

class BusinessCalculator {
  BusinessCalculator._();

  /// Derives current stock per item from the full purchase/sale history.
  /// Mirrors the previous SQLite rebuild-on-write formula, but is computed
  /// on demand from data already held in memory instead of a separate
  /// persisted table.
  static List<StockEntry> computeStock({
    required List<Item> items,
    required List<Purchase> purchases,
    required List<Sale> sales,
  }) {
    final entries = items.map((item) {
      final itemPurchases = purchases.where((p) => p.itemId == item.id);
      final itemSales = sales.where((s) => s.itemId == item.id);
      final purchasedQuantity = itemPurchases.fold<double>(
        0,
        (total, p) => total + p.quantity,
      );
      final purchasedWeight = itemPurchases.fold<double>(
        0,
        (total, p) => total + p.weight,
      );
      final purchasedAmount = itemPurchases.fold<double>(
        0,
        (total, p) => total + p.totalAmount,
      );
      final soldQuantity = itemSales.fold<double>(
        0,
        (total, s) => total + s.quantity,
      );
      final soldWeight = itemSales.fold<double>(
        0,
        (total, s) => total + s.weight,
      );
      final availableWeight = purchasedWeight - soldWeight;
      final averageRate = purchasedWeight == 0
          ? 0.0
          : purchasedAmount / purchasedWeight;
      return StockEntry(
        itemId: item.id!,
        itemName: item.name,
        category: item.category,
        unit: item.unit,
        lowStockThreshold: item.lowStockThreshold,
        availableQuantity: purchasedQuantity - soldQuantity,
        availableWeight: availableWeight,
        averagePurchaseRate: averageRate,
        totalStockValue: availableWeight * averageRate,
      );
    }).toList();
    entries.sort((a, b) {
      final byCategory = a.category.compareTo(b.category);
      return byCategory != 0 ? byCategory : a.itemName.compareTo(b.itemName);
    });
    return entries;
  }

  static BusinessSummary summarize({
    required List<Purchase> purchases,
    required List<Sale> sales,
    required List<Expense> expenses,
    DateTime? start,
    DateTime? end,
  }) {
    final filteredPurchases = purchases.where(
      (entry) => _inside(entry.date, start, end),
    );
    final filteredSales = sales.where(
      (entry) => _inside(entry.date, start, end),
    );
    final filteredExpenses = expenses.where(
      (entry) => _inside(entry.date, start, end),
    );
    final purchaseTotal = filteredPurchases.fold<double>(
      0,
      (total, entry) => total + entry.totalAmount,
    );
    final salesTotal = filteredSales.fold<double>(
      0,
      (total, entry) => total + entry.totalAmount,
    );
    final saleTransport = filteredSales.fold<double>(
      0,
      (total, entry) => total + entry.transportCharges,
    );
    final expensesTotal =
        filteredExpenses.fold<double>(
          0,
          (total, entry) => total + entry.amount,
        ) +
        saleTransport;
    final grossProfit = salesTotal - purchaseTotal;
    return BusinessSummary(
      purchaseTotal: purchaseTotal,
      salesTotal: salesTotal,
      grossProfit: grossProfit,
      expensesTotal: expensesTotal,
      netProfit: grossProfit - expensesTotal,
      purchaseWeight: filteredPurchases.fold<double>(
        0,
        (total, entry) => total + entry.weight,
      ),
      salesWeight: filteredSales.fold<double>(
        0,
        (total, entry) => total + entry.weight,
      ),
      pendingPayments: filteredSales.fold<double>(0, (total, entry) {
        if (entry.paymentStatus == 'Pending') {
          return total + entry.totalAmount;
        }
        if (entry.paymentStatus == 'Partial') {
          return total + (entry.totalAmount / 2);
        }
        return total;
      }),
    );
  }

  static List<DailyTrend> trends({
    required List<Purchase> purchases,
    required List<Sale> sales,
    required List<Expense> expenses,
    int days = 7,
  }) {
    final today = DateTime.now();
    return List.generate(days, (index) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: days - index - 1));
      final summary = summarize(
        purchases: purchases,
        sales: sales,
        expenses: expenses,
        start: date,
        end: date,
      );
      return DailyTrend(
        date: date,
        purchase: summary.purchaseTotal,
        sales: summary.salesTotal,
        profit: summary.netProfit,
      );
    });
  }

  static bool _inside(DateTime date, DateTime? start, DateTime? end) {
    final day = DateTime(date.year, date.month, date.day);
    final first = start == null
        ? null
        : DateTime(start.year, start.month, start.day);
    final last = end == null ? null : DateTime(end.year, end.month, end.day);
    return (first == null || !day.isBefore(first)) &&
        (last == null || !day.isAfter(last));
  }
}
