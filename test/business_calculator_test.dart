import 'package:flutter_test/flutter_test.dart';
import 'package:scrap_tyre_business_manager/models/expense.dart';
import 'package:scrap_tyre_business_manager/models/purchase.dart';
import 'package:scrap_tyre_business_manager/models/sale.dart';
import 'package:scrap_tyre_business_manager/services/business_calculator.dart';

void main() {
  test('net profit subtracts purchase, expense and sales transport cost', () {
    final date = DateTime(2026, 5, 26);
    final summary = BusinessCalculator.summarize(
      purchases: [
        Purchase(
          date: date,
          supplierName: 'Supplier',
          vehicleNumber: 'TN 01 A 1',
          itemId: 1,
          itemName: 'Car Tyre',
          quantity: 10,
          weight: 100,
          rate: 30,
          totalAmount: 3000,
          paymentType: 'Cash',
          notes: '',
        ),
      ],
      sales: [
        Sale(
          date: date,
          customerName: 'Customer',
          itemId: 1,
          itemName: 'Car Tyre',
          quantity: 5,
          weight: 50,
          rate: 50,
          totalAmount: 2500,
          transportCharges: 100,
          paymentStatus: 'Pending',
          notes: '',
        ),
      ],
      expenses: [Expense(date: date, type: 'Labour', amount: 200, notes: '')],
    );

    expect(summary.grossProfit, -500);
    expect(summary.expensesTotal, 300);
    expect(summary.netProfit, -800);
    expect(summary.pendingPayments, 2500);
  });

  test('date filtering includes only entries within selected range', () {
    final summary = BusinessCalculator.summarize(
      purchases: const [],
      sales: [
        Sale(
          date: DateTime(2026, 5, 25),
          customerName: 'A',
          itemId: 1,
          itemName: 'Tube KG',
          quantity: 0,
          weight: 10,
          rate: 50,
          totalAmount: 500,
          transportCharges: 0,
          paymentStatus: 'Paid',
          notes: '',
        ),
        Sale(
          date: DateTime(2026, 5, 26),
          customerName: 'B',
          itemId: 1,
          itemName: 'Tube KG',
          quantity: 0,
          weight: 10,
          rate: 60,
          totalAmount: 600,
          transportCharges: 0,
          paymentStatus: 'Paid',
          notes: '',
        ),
      ],
      expenses: const [],
      start: DateTime(2026, 5, 26),
      end: DateTime(2026, 5, 26),
    );

    expect(summary.salesTotal, 600);
  });
}
