import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business_profile.dart';
import '../providers/business_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/form_fields.dart';
import '../widgets/section_header.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessName;
  late final TextEditingController _ownerName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _taxId;

  @override
  void initState() {
    super.initState();
    final profile = context.read<BusinessProvider>().profile;
    _businessName = TextEditingController(text: profile.businessName);
    _ownerName = TextEditingController(text: profile.ownerName);
    _phone = TextEditingController(text: profile.phone);
    _address = TextEditingController(text: profile.address);
    _taxId = TextEditingController(text: profile.taxId);
  }

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _address.dispose();
    _taxId.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<BusinessProvider>().saveProfile(
      BusinessProfile(
        businessName: _businessName.text.trim(),
        ownerName: _ownerName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        taxId: _taxId.text.trim().toUpperCase(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business profile saved.')));
  }

  Future<void> _clearDemoData() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear demo data?'),
            content: const Text(
              'This removes only the sample purchases, sales and expenses. '
              'Entries you add yourself are kept.',
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
    if (!confirmed || !mounted) return;
    await context.read<BusinessProvider>().clearDemoData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo data cleared. You can enter real records now.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDemoData = context.watch<BusinessProvider>().hasDemoData;
    return Scaffold(
      appBar: AppBar(title: const Text('Business Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
        children: [
          const SectionHeader(
            title: 'Shop Profile',
            subtitle: 'Used for your app header and shared reports',
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _businessName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Shop / Business Name *',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (value) =>
                          requiredText(value, 'Business name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      textCapitalization: TextCapitalization.words,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Business Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taxId,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'GSTIN / Registration No.',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 17),
                    FilledButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Business Profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Testing Data',
            subtitle: 'Control the sample records included for testing',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        (hasDemoData ? AppTheme.orange : AppTheme.green)
                            .withValues(alpha: 0.13),
                    foregroundColor: hasDemoData
                        ? AppTheme.orange
                        : AppTheme.green,
                    child: Icon(
                      hasDemoData
                          ? Icons.science_outlined
                          : Icons.check_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasDemoData
                          ? 'Demo entries are currently visible in your totals.'
                          : 'Demo data has been cleared.',
                    ),
                  ),
                  if (hasDemoData)
                    TextButton(
                      onPressed: _clearDemoData,
                      child: const Text('Clear'),
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
