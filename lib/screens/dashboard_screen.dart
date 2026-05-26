import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/business_summary.dart';
import '../providers/business_provider.dart';
import '../utils/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenExpense,
    required this.onOpenSettings,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenExpense;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }
    final today = provider.todaySummary;
    final allTime = provider.summaryFor(null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        if (provider.hasDemoData) ...[
          const _DemoDataBanner(),
          const SizedBox(height: 12),
        ],
        if (!provider.profile.isConfigured) ...[
          _ProfilePrompt(onOpenSettings: onOpenSettings),
          const SizedBox(height: 12),
        ],
        SectionHeader(
          title: context.tr('todayOverview'),
          subtitle: DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.22,
          children: [
            SummaryCard(
              label: 'Today Purchase Amount',
              value: AppFormatters.compactMoney(today.purchaseTotal),
              icon: Icons.shopping_cart_rounded,
              color: AppTheme.navy,
            ),
            SummaryCard(
              label: 'Today Sales Amount',
              value: AppFormatters.compactMoney(today.salesTotal),
              icon: Icons.point_of_sale_rounded,
              color: AppTheme.green,
            ),
            SummaryCard(
              label: 'Today Profit',
              value: AppFormatters.compactMoney(today.netProfit),
              icon: Icons.trending_up_rounded,
              color: AppTheme.green,
              negative: today.netProfit < 0,
            ),
            SummaryCard(
              label: 'Current Stock',
              value: AppFormatters.weight(provider.stockWeight),
              icon: Icons.inventory_2_rounded,
              color: AppTheme.orange,
            ),
            SummaryCard(
              label: 'Total Weight Purchased',
              value: AppFormatters.weight(allTime.purchaseWeight),
              icon: Icons.scale_rounded,
              color: AppTheme.navy,
            ),
            SummaryCard(
              label: 'Total Weight Sold',
              value: AppFormatters.weight(allTime.salesWeight),
              icon: Icons.local_shipping_rounded,
              color: AppTheme.green,
            ),
            SummaryCard(
              label: 'Pending Payments',
              value: AppFormatters.compactMoney(allTime.pendingPayments),
              icon: Icons.schedule_rounded,
              color: AppTheme.orange,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Fast Entry'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DashboardAction(
                icon: Icons.add_shopping_cart_rounded,
                label: 'Purchase',
                color: AppTheme.navy,
                onTap: () => onOpenTab(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashboardAction(
                icon: Icons.sell_rounded,
                label: 'Sale',
                color: AppTheme.green,
                onTap: () => onOpenTab(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashboardAction(
                icon: Icons.receipt_rounded,
                label: 'Expense',
                color: AppTheme.orange,
                onTap: onOpenExpense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SalesPurchaseChart(provider: provider),
        const SizedBox(height: 14),
        _ProfitChart(provider: provider),
        const SizedBox(height: 14),
        _StockSummary(provider: provider),
      ],
    );
  }
}

class _DemoDataBanner extends StatelessWidget {
  const _DemoDataBanner();

  Future<void> _clear(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear demo data?'),
            content: const Text(
              'Only the included sample entries will be removed. Your own '
              'purchases, sales and expenses will remain.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear Demo Data'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await context.read<BusinessProvider>().clearDemoData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demo data cleared. Add your first real purchase to begin.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: AppTheme.orange),
              SizedBox(width: 8),
              Text(
                'DEMO DATA ACTIVE',
                style: TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Dashboard totals include sample entries for testing. Clear them '
            'before recording real business transactions.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _clear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear Demo Data'),
          ),
        ],
      ),
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          foregroundColor: AppTheme.navy,
          child: Icon(Icons.storefront_outlined),
        ),
        title: const Text(
          'Set up your shop profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Add your business name for reports and invoices.',
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
        onTap: onOpenSettings,
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesPurchaseChart extends StatelessWidget {
  const _SalesPurchaseChart({required this.provider});

  final BusinessProvider provider;

  @override
  Widget build(BuildContext context) {
    final trends = provider.trends;
    return _ChartCard(
      title: 'Daily Sales vs Purchase',
      subtitle: 'Last 7 days',
      legend: const [
        _Legend(color: AppTheme.navy, label: 'Purchase'),
        _Legend(color: AppTheme.green, label: 'Sales'),
      ],
      chart: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: _titles(trends),
          barTouchData: BarTouchData(enabled: false),
          barGroups: List.generate(trends.length, (index) {
            final point = trends[index];
            return BarChartGroupData(
              x: index,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: point.purchase,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.navy,
                ),
                BarChartRodData(
                  toY: point.sales,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: AppTheme.green,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ProfitChart extends StatelessWidget {
  const _ProfitChart({required this.provider});

  final BusinessProvider provider;

  @override
  Widget build(BuildContext context) {
    final trends = provider.trends;
    final spots = List.generate(
      trends.length,
      (index) => FlSpot(index.toDouble(), trends[index].profit),
    );
    return _ChartCard(
      title: 'Profit Trend',
      subtitle: 'Net profit after expenses',
      legend: const [_Legend(color: AppTheme.orange, label: 'Net Profit')],
      chart: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: _titles(trends),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.orange,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.orange.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

FlTitlesData _titles(List<DailyTrend> trends) => FlTitlesData(
  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 27,
      getTitlesWidget: (value, meta) {
        final index = value.round();
        if (index < 0 || index >= trends.length) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            DateFormat('dd').format(trends[index].date),
            style: const TextStyle(fontSize: 10),
          ),
        );
      },
    ),
  ),
);

class _StockSummary extends StatelessWidget {
  const _StockSummary({required this.provider});

  final BusinessProvider provider;

  @override
  Widget build(BuildContext context) {
    final available =
        provider.stock.where((item) => item.availableWeight > 0).toList()..sort(
          (first, second) =>
              second.availableWeight.compareTo(first.availableWeight),
        );
    final topItems = available.take(4).toList();
    final maxWeight = topItems.isEmpty
        ? 1.0
        : topItems.first.availableWeight.clamp(1, double.infinity);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Item-wise Stock Summary',
              subtitle: 'Highest available weight',
            ),
            const SizedBox(height: 14),
            for (final item in topItems) ...[
              Row(
                children: [
                  Expanded(child: Text(item.itemName)),
                  Text(
                    AppFormatters.weight(item.availableWeight),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: item.availableWeight / maxWeight,
                minHeight: 7,
                borderRadius: BorderRadius.circular(6),
                color: AppTheme.green,
                backgroundColor: AppTheme.green.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 13),
            ],
            if (topItems.isEmpty)
              const Text('No stock is currently available.'),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.legend,
    required this.chart,
  });

  final String title;
  final String subtitle;
  final List<Widget> legend;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: legend),
            const SizedBox(height: 12),
            SizedBox(height: 150, child: chart),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Container(
            height: 9,
            width: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
