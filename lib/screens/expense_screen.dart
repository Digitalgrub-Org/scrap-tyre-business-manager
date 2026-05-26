import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/expense.dart';
import '../providers/business_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/form_fields.dart';
import '../widgets/section_header.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  String _type = AppConstants.expenseTypes.first;
  int? _editingId;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _reset() {
    _formKey.currentState?.reset();
    setState(() {
      _date = DateTime.now();
      _type = AppConstants.expenseTypes.first;
      _editingId = null;
      _amount.clear();
      _notes.clear();
    });
  }

  void _edit(Expense expense) {
    setState(() {
      _editingId = expense.id;
      _date = expense.date;
      _type = expense.type;
      _amount.text = expense.amount.toStringAsFixed(2);
      _notes.text = expense.notes;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<BusinessProvider>().saveExpense(
      Expense(
        id: _editingId,
        date: _date,
        type: _type,
        amount: double.parse(_amount.text),
        notes: _notes.text.trim(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingId == null
              ? 'Expense saved successfully.'
              : 'Expense updated successfully.',
        ),
      ),
    );
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          if (_editingId != null)
            TextButton(onPressed: _reset, child: const Text('Cancel')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionHeader(
            title: _editingId == null ? 'Add Expense' : 'Edit Expense',
            subtitle: 'Expenses directly reduce net profit',
          ),
          const SizedBox(height: 13),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    EntryDateField(
                      date: _date,
                      onChanged: (date) => setState(() => _date = date),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Expense Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: AppConstants.expenseTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      validator: (value) => positiveNumber(value, 'amount'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 17),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        _editingId == null ? 'Save Expense' : 'Update Expense',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),
          const SectionHeader(title: 'Expense History'),
          const SizedBox(height: 12),
          for (final expense in provider.expenses)
            Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  foregroundColor: AppTheme.orange,
                  backgroundColor: AppTheme.orange.withValues(alpha: 0.13),
                  child: const Icon(Icons.receipt_long_outlined),
                ),
                title: Text(
                  expense.type,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${AppFormatters.date.format(expense.date)}'
                  '${expense.notes.isEmpty ? '' : ' | ${expense.notes}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppFormatters.money(expense.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') _edit(expense);
                        if (action == 'delete' &&
                            await confirmDeletion(context, expense.type) &&
                            context.mounted) {
                          await context.read<BusinessProvider>().deleteExpense(
                            expense,
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
