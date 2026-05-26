class BusinessSummary {
  const BusinessSummary({
    required this.purchaseTotal,
    required this.salesTotal,
    required this.grossProfit,
    required this.expensesTotal,
    required this.netProfit,
    required this.purchaseWeight,
    required this.salesWeight,
    required this.pendingPayments,
  });

  final double purchaseTotal;
  final double salesTotal;
  final double grossProfit;
  final double expensesTotal;
  final double netProfit;
  final double purchaseWeight;
  final double salesWeight;
  final double pendingPayments;
}

class DailyTrend {
  const DailyTrend({
    required this.date,
    required this.purchase,
    required this.sales,
    required this.profit,
  });

  final DateTime date;
  final double purchase;
  final double sales;
  final double profit;
}
