import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../models/item.dart';
import '../models/sale.dart';
import '../models/stock_entry.dart';
import '../providers/business_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/form_fields.dart';
import '../widgets/item_selector.dart';
import '../widgets/section_header.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _customer = TextEditingController();
  final _quantity = TextEditingController();
  final _weight = TextEditingController();
  final _rate = TextEditingController();
  final _transport = TextEditingController(text: '0');
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  Item? _item;
  String _paymentStatus = AppConstants.paymentStatuses.first;
  String? _editingId;

  double get _total =>
      (double.tryParse(_weight.text) ?? 0) * (double.tryParse(_rate.text) ?? 0);
  double get _transportAmount => double.tryParse(_transport.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _weight.addListener(_recalculate);
    _rate.addListener(_recalculate);
    _transport.addListener(_recalculate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _customer.dispose();
    _quantity.dispose();
    _weight.dispose();
    _rate.dispose();
    _transport.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _recalculate() => setState(() {});

  void _reset() {
    _formKey.currentState?.reset();
    setState(() {
      _date = DateTime.now();
      _item = null;
      _paymentStatus = AppConstants.paymentStatuses.first;
      _editingId = null;
      _customer.clear();
      _quantity.clear();
      _weight.clear();
      _rate.clear();
      _transport.text = '0';
      _notes.clear();
    });
  }

  void _load(Sale sale, {required bool duplicate}) {
    final provider = context.read<BusinessProvider>();
    setState(() {
      _editingId = duplicate ? null : sale.id;
      _date = duplicate ? DateTime.now() : sale.date;
      _item = provider.items
          .where((item) => item.id == sale.itemId)
          .firstOrNull;
      _customer.text = sale.customerName;
      _quantity.text = sale.quantity.toStringAsFixed(2);
      _weight.text = sale.weight.toStringAsFixed(2);
      _rate.text = sale.rate.toStringAsFixed(2);
      _transport.text = sale.transportCharges.toStringAsFixed(2);
      _paymentStatus = sale.paymentStatus;
      _notes.text = sale.notes;
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
              ? 'Sale duplicated. Review available stock before saving.'
              : 'Editing sale entry.',
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
    final sale = Sale(
      id: _editingId,
      date: _date,
      customerName: _customer.text.trim(),
      itemId: _item!.id!,
      itemName: _item!.name,
      quantity: double.parse(_quantity.text),
      weight: double.parse(_weight.text),
      rate: double.parse(_rate.text),
      totalAmount: _total,
      transportCharges: _transportAmount,
      paymentStatus: _paymentStatus,
      notes: _notes.text.trim(),
    );
    final validationError = await context.read<BusinessProvider>().saveSale(
      sale,
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
              ? 'Sale saved and stock reduced.'
              : 'Sale updated successfully.',
        ),
      ),
    );
    _reset();
  }

  Future<void> _shareInvoice(Sale sale) async {
    final profile = context.read<BusinessProvider>().profile;
    final businessName = profile.isConfigured
        ? profile.businessName
        : AppConstants.appName;
    final invoice =
        '''
$businessName
${profile.address.isEmpty ? '' : '${profile.address}\n'}${profile.phone.isEmpty ? '' : 'Phone: ${profile.phone}\n'}
Sales Invoice
Date: ${AppFormatters.date.format(sale.date)}
Customer: ${sale.customerName}
Item: ${sale.itemName}
Weight: ${AppFormatters.weight(sale.weight)}
Rate: ${AppFormatters.money(sale.rate)}/kg
Transport: ${AppFormatters.money(sale.transportCharges)}
Total: ${AppFormatters.money(sale.totalAmount)}
Payment: ${sale.paymentStatus}
''';
    await SharePlus.instance.share(
      ShareParams(
        text: invoice,
        subject: 'Sales Invoice - ${sale.customerName}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final stock = provider.stock
        .where((entry) => entry.itemId == _item?.id)
        .cast<StockEntry?>()
        .firstOrNull;
    final saleWeight = double.tryParse(_weight.text) ?? 0;
    final estimatedProfit =
        _total -
        (saleWeight * (stock?.averagePurchaseRate ?? 0)) -
        _transportAmount;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        SectionHeader(
          title: _editingId == null ? 'Sales Entry' : 'Edit Sale',
          subtitle: 'Sales cannot exceed available stock',
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
                    controller: _customer,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => requiredText(value, 'Customer name'),
                  ),
                  const SizedBox(height: 12),
                  ItemSelectField(
                    items: provider.items,
                    selectedItem: _item,
                    onSelected: (item) => setState(() => _item = item),
                  ),
                  if (stock != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 7, 4, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available: ${AppFormatters.quantity.format(stock.availableQuantity)} qty / '
                          '${AppFormatters.weight(stock.availableWeight)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.green),
                        ),
                      ),
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
                    label: 'Sales Rate / kg *',
                    icon: Icons.currency_rupee_rounded,
                    validator: (value) => positiveNumber(value, 'rate'),
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _transport,
                    label: 'Transport Charges',
                    icon: Icons.local_shipping_outlined,
                    validator: (value) => positiveNumber(
                      value,
                      'transport charges',
                      allowZero: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AmountPanel(
                    label: 'Total Sales Amount',
                    amount: _total,
                    secondary:
                        'Estimated margin after stock cost and transport: '
                        '${AppFormatters.money(estimatedProfit)}',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: AppConstants.paymentStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _paymentStatus = value!),
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
                      _editingId == null ? 'Save Sale' : 'Update Sale',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Recent Sales',
          subtitle: 'Invoice sharing and repeat-sale shortcuts',
        ),
        const SizedBox(height: 12),
        for (final sale in provider.sales.take(8))
          _SalesTile(
            sale: sale,
            onShare: () => _shareInvoice(sale),
            onEdit: () => _load(sale, duplicate: false),
            onDuplicate: () => _load(sale, duplicate: true),
            onDelete: () async {
              if (await confirmDeletion(context, sale.itemName) &&
                  context.mounted) {
                await context.read<BusinessProvider>().deleteSale(sale);
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

class _SalesTile extends StatelessWidget {
  const _SalesTile({
    required this.sale,
    required this.onShare,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Sale sale;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.green.withValues(alpha: 0.12),
          foregroundColor: AppTheme.green,
          child: const Icon(Icons.point_of_sale_outlined),
        ),
        title: Text(
          sale.itemName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${sale.customerName} | ${AppFormatters.date.format(sale.date)}\n'
          '${AppFormatters.weight(sale.weight)} | ${sale.paymentStatus}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.money(sale.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: 29,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (action) {
                  if (action == 'share') onShare();
                  if (action == 'edit') onEdit();
                  if (action == 'duplicate') onDuplicate();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'share', child: Text('Share invoice')),
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
