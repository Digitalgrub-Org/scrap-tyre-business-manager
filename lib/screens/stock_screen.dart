import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock_entry.dart';
import '../providers/business_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_header.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String _search = '';
  String? _category;
  bool _lowOnly = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final categories = provider.stock
        .map((item) => item.category)
        .toSet()
        .toList();
    final visible = provider.stock.where((entry) {
      final matchesName = entry.itemName.toLowerCase().contains(
        _search.toLowerCase(),
      );
      final matchesCategory = _category == null || entry.category == _category;
      final matchesAlert = !_lowOnly || entry.isLowStock;
      return matchesName && matchesCategory && matchesAlert;
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        SectionHeader(
          title: 'Stock Management',
          subtitle:
              '${visible.length} items | Stock value ${AppFormatters.money(provider.stockValue)}',
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) => setState(() => _search = value),
          decoration: const InputDecoration(
            hintText: 'Search stock item',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...categories.map(
                    (category) => DropdownMenuItem<String?>(
                      value: category,
                      child: Text(category),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _category = value),
              ),
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: _lowOnly,
              avatar: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('Low stock'),
              onSelected: (value) => setState(() => _lowOnly = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final entry in visible) _StockCard(entry: entry),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('No stock items match these filters.')),
          ),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.entry});

  final StockEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.isLowStock
        ? Theme.of(context).colorScheme.error
        : AppTheme.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        entry.category,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (entry.isLowStock)
                  Chip(
                    side: BorderSide.none,
                    avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: const Text('Low'),
                    labelStyle: TextStyle(color: color),
                    backgroundColor: color.withValues(alpha: 0.1),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _Metric(
                  label: 'Quantity',
                  value: AppFormatters.quantity.format(entry.availableQuantity),
                ),
                _Metric(
                  label: 'Weight',
                  value: AppFormatters.weight(entry.availableWeight),
                ),
                _Metric(
                  label: 'Avg Rate',
                  value: AppFormatters.money(entry.averagePurchaseRate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Stock Value',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  AppFormatters.money(entry.totalStockValue),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
