import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class EntryDateField extends StatelessWidget {
  const EntryDateField({
    super.key,
    required this.date,
    required this.onChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (selected != null) onChanged(selected);
      },
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date *',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(AppFormatters.date.format(date)),
      ),
    );
  }
}

class AmountPanel extends StatelessWidget {
  const AmountPanel({
    super.key,
    required this.label,
    required this.amount,
    this.secondary,
  });

  final String label;
  final double amount;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_outlined, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  AppFormatters.money(amount),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (secondary != null)
                  Text(
                    secondary!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? requiredText(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required.';
  return null;
}

String? positiveNumber(String? value, String label, {bool allowZero = false}) {
  final parsed = double.tryParse(value ?? '');
  if (parsed == null) return 'Enter a valid $label.';
  if (allowZero ? parsed < 0 : parsed <= 0) {
    return '$label must be ${allowZero ? 'zero or more' : 'greater than zero'}.';
  }
  return null;
}

Future<bool> confirmDeletion(BuildContext context, String description) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete entry?'),
          content: Text('Delete $description? Stock and totals will update.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}
