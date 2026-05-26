import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../models/report_row.dart';
import '../providers/business_provider.dart';
import '../services/report_export_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.onOpenExpense});

  final VoidCallback onOpenExpense;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchController = TextEditingController();
  final _exportService = ReportExportService();
  late DateTimeRange _range;
  String _type = AppConstants.reportTypes.first;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _range = DateTimeRange(start: today, end: today);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _usePreset(String type) {
    final now = DateTime.now();
    setState(() {
      _type = type;
      if (type == 'Daily Report') {
        _range = DateTimeRange(start: now, end: now);
      } else if (type == 'Weekly Report') {
        _range = DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      } else if (type == 'Monthly Report') {
        _range = DateTimeRange(start: DateTime(now.year, now.month), end: now);
      }
    });
  }

  Future<void> _chooseRange() async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected != null) setState(() => _range = selected);
  }

  Future<void> _export({required bool excel, required bool share}) async {
    setState(() => _exporting = true);
    try {
      final provider = context.read<BusinessProvider>();
      final file = excel
          ? await _exportService.exportExcel(
              provider: provider,
              type: _type,
              range: _range,
              search: _searchController.text,
            )
          : await _exportService.exportPdf(
              provider: provider,
              type: _type,
              range: _range,
              search: _searchController.text,
            );
      if (!mounted) return;
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [file],
            text: '$_type from Scrap Tyre Business Manager',
            subject: _type,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${excel ? 'Excel' : 'PDF'} report generated and ready to share.',
            ),
          ),
        );
        await SharePlus.instance.share(
          ShareParams(files: [file], subject: _type),
        );
      }
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report export failed: $exception'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final summary = provider.summaryFor(_range);
    final rows = _exportService.rowsFor(
      provider: provider,
      type: _type,
      range: _range,
      search: _searchController.text,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        SectionHeader(
          title: 'Reports',
          subtitle: 'Profit formula: Sales - Purchase - Expenses',
          action: IconButton.filledTonal(
            tooltip: 'Manage expenses',
            onPressed: widget.onOpenExpense,
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(
            labelText: 'Report Type',
            prefixIcon: Icon(Icons.description_outlined),
          ),
          items: AppConstants.reportTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) => _usePreset(value!),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _chooseRange,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date Range',
              prefixIcon: Icon(Icons.date_range_outlined),
              suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
            ),
            child: Text(
              '${AppFormatters.date.format(_range.start)} - ${AppFormatters.date.format(_range.end)}',
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search item, customer or supplier',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.35,
          children: [
            SummaryCard(
              label: 'Total Purchase',
              value: AppFormatters.compactMoney(summary.purchaseTotal),
              icon: Icons.shopping_cart_rounded,
              color: AppTheme.navy,
            ),
            SummaryCard(
              label: 'Total Sales',
              value: AppFormatters.compactMoney(summary.salesTotal),
              icon: Icons.sell_rounded,
              color: AppTheme.green,
            ),
            SummaryCard(
              label: 'Expenses',
              value: AppFormatters.compactMoney(summary.expensesTotal),
              icon: Icons.receipt_rounded,
              color: AppTheme.orange,
            ),
            SummaryCard(
              label: 'Net Profit',
              value: AppFormatters.compactMoney(summary.netProfit),
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.green,
              negative: summary.netProfit < 0,
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exporting
                    ? null
                    : () => _export(excel: false, share: false),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exporting
                    ? null
                    : () => _export(excel: true, share: false),
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Excel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _exporting
                    ? null
                    : () => _export(excel: false, share: true),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
        if (_exporting)
          const Padding(
            padding: EdgeInsets.only(top: 9),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 22),
        SectionHeader(title: _type, subtitle: '${rows.length} entries found'),
        const SizedBox(height: 11),
        for (final row in rows) _ReportRowCard(row: row),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('No entries found for this report.')),
          ),
      ],
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({required this.row});

  final ReportRow row;

  @override
  Widget build(BuildContext context) {
    final negative = row.amount < 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          row.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(row.detail),
        trailing: Text(
          AppFormatters.money(row.amount),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: negative
                ? Theme.of(context).colorScheme.error
                : AppTheme.green,
          ),
        ),
      ),
    );
  }
}
