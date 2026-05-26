import '../models/business_summary.dart';
import '../models/expense.dart';
import '../models/purchase.dart';
import '../models/sale.dart';

class BusinessCalculator {
  BusinessCalculator._();

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
