import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/item.dart';
import '../models/purchase.dart';
import '../providers/business_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/form_fields.dart';
import '../widgets/item_selector.dart';
import '../widgets/section_header.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _supplier = TextEditingController();
  final _vehicle = TextEditingController();
  final _quantity = TextEditingController();
  final _weight = TextEditingController();
  final _rate = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  Item? _item;
  String _paymentType = AppConstants.paymentTypes.first;
  String? _editingId;

  double get _total =>
      (double.tryParse(_weight.text) ?? 0) * (double.tryParse(_rate.text) ?? 0);

  @override
  void initState() {
    super.initState();
    _weight.addListener(_recalculate);
    _rate.addListener(_recalculate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _supplier.dispose();
    _vehicle.dispose();
    _quantity.dispose();
    _weight.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _recalculate() => setState(() {});

  void _reset() {
    _formKey.currentState?.reset();
    setState(() {
      _date = DateTime.now();
      _item = null;
      _paymentType = AppConstants.paymentTypes.first;
      _editingId = null;
      _supplier.clear();
      _vehicle.clear();
      _quantity.clear();
      _weight.clear();
      _rate.clear();
      _notes.clear();
    });
  }

  void _load(Purchase purchase, {required bool duplicate}) {
    final provider = context.read<BusinessProvider>();
    setState(() {
      _editingId = duplicate ? null : purchase.id;
      _date = duplicate ? DateTime.now() : purchase.date;
      _item = provider.items
          .where((item) => item.id == purchase.itemId)
          .firstOrNull;
      _supplier.text = purchase.supplierName;
      _vehicle.text = purchase.vehicleNumber;
      _quantity.text = purchase.quantity.toStringAsFixed(2);
      _weight.text = purchase.weight.toStringAsFixed(2);
      _rate.text = purchase.rate.toStringAsFixed(2);
      _paymentType = purchase.paymentType;
      _notes.text = purchase.notes;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          duplicate
              ? 'Purchase duplicated. Review and save.'
              : 'Editing purchase entry.',
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_item == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an item type.')));
      return;
    }
    final purchase = Purchase(
      id: _editingId,
      date: _date,
      supplierName: _supplier.text.trim(),
      vehicleNumber: _vehicle.text.trim().toUpperCase(),
      itemId: _item!.id!,
      itemName: _item!.name,
      quantity: double.parse(_quantity.text),
      weight: double.parse(_weight.text),
      rate: double.parse(_rate.text),
      totalAmount: _total,
      paymentType: _paymentType,
      notes: _notes.text.trim(),
    );
    final validationError = await context.read<BusinessProvider>().savePurchase(
      purchase,
    );
    if (!mounted) return;
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingId == null
              ? 'Purchase saved and stock increased.'
              : 'Purchase updated successfully.',
        ),
      ),
    );
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        SectionHeader(
          title: _editingId == null ? 'Purchase Entry' : 'Edit Purchase',
          subtitle: 'Incoming scrap updates stock immediately',
          action: _editingId == null
              ? null
              : TextButton(onPressed: _reset, child: const Text('Cancel')),
        ),
        const SizedBox(height: 14),
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
                  TextFormField(
                    controller: _supplier,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Name *',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    validator: (value) => requiredText(value, 'Supplier name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicle,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Number *',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    validator: (value) => requiredText(value, 'Vehicle number'),
                  ),
                  const SizedBox(height: 12),
                  ItemSelectField(
                    items: provider.items,
                    selectedItem: _item,
                    onSelected: (item) => setState(() => _item = item),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          controller: _quantity,
                          label: 'Quantity *',
                          icon: Icons.numbers_rounded,
                          validator: (value) => positiveNumber(
                            value,
                            'quantity',
                            allowZero: _item?.unit == 'KG',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _numberField(
                          controller: _weight,
                          label: 'Weight (kg) *',
                          icon: Icons.scale_outlined,
                          validator: (value) => positiveNumber(value, 'weight'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _rate,
                    label: 'Purchase Rate / kg *',
                    icon: Icons.currency_rupee_rounded,
                    validator: (value) => positiveNumber(value, 'rate'),
                  ),
                  const SizedBox(height: 12),
                  AmountPanel(label: 'Total Purchase Amount', amount: _total),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentType,
                    decoration: const InputDecoration(
                      labelText: 'Payment Type',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: AppConstants.paymentTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _paymentType = value!),
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
                      _editingId == null ? 'Save Purchase' : 'Update Purchase',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Recent Purchases',
          subtitle: 'Edit, delete or duplicate repeat entries',
        ),
        const SizedBox(height: 12),
        for (final purchase in provider.purchases.take(8))
          _PurchaseTile(
            purchase: purchase,
            onEdit: () => _load(purchase, duplicate: false),
            onDuplicate: () => _load(purchase, duplicate: true),
            onDelete: () async {
              if (await confirmDeletion(context, purchase.itemName) &&
                  context.mounted) {
                final error = await context
                    .read<BusinessProvider>()
                    .deletePurchase(purchase);
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({
    required this.purchase,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Purchase purchase;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.navy.withValues(alpha: 0.1),
          foregroundColor: AppTheme.navy,
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        title: Text(
          purchase.itemName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${purchase.supplierName} | ${AppFormatters.date.format(purchase.date)}\n'
          '${AppFormatters.weight(purchase.weight)} at ${AppFormatters.money(purchase.rate)}/kg',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.money(purchase.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: 29,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'duplicate') onDuplicate();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
