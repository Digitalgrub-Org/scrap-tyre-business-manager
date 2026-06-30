import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/business_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_localizations.dart';
import 'business_settings_screen.dart';
import 'dashboard_screen.dart';
import 'expense_screen.dart';
import 'purchase_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
import 'stock_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _openExpense() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ExpenseScreen()));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BusinessSettingsScreen()),
    );
  }

  Future<void> _signOut() async {
    final isGuest = AuthService().currentUser?.isAnonymous ?? false;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isGuest ? 'Leave guest mode?' : 'Sign out?'),
        content: Text(
          isGuest
              ? 'You are in guest mode. Guest data is not tied to an email, so '
                  'signing out will lose access to it. Create an account instead '
                  'to keep your records.'
              : 'You will need to sign in again to access your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
    }
  }

  void _openQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('quickEntry'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _QuickAction(
                icon: Icons.shopping_cart_checkout_rounded,
                color: const Color(0xFF12304A),
                title: 'Add Purchase',
                subtitle: 'Record incoming scrap and increase stock',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 1);
                },
              ),
              _QuickAction(
                icon: Icons.point_of_sale_rounded,
                color: const Color(0xFF118A64),
                title: 'Add Sale',
                subtitle: 'Record outgoing stock and customer payment',
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 2);
                },
              ),
              _QuickAction(
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFFE88B2A),
                title: context.tr('addExpense'),
                subtitle: 'Loading, transport, labour or other costs',
                onTap: () {
                  Navigator.pop(context);
                  _openExpense();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BusinessProvider>().profile;
    final screens = [
      DashboardScreen(
        onOpenTab: (index) => setState(() => _selectedIndex = index),
        onOpenExpense: _openExpense,
        onOpenSettings: _openSettings,
      ),
      const PurchaseScreen(),
      const SalesScreen(),
      const StockScreen(),
      ReportsScreen(onOpenExpense: _openExpense),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.isConfigured
                  ? profile.businessName
                  : AppConstants.appName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              profile.isConfigured
                  ? AppConstants.appName
                  : AppConstants.appSubtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'தமிழ் / English',
            onPressed: context.read<SettingsProvider>().toggleLanguage,
            icon: const Icon(Icons.translate_rounded),
          ),
          IconButton(
            tooltip: 'Light / dark mode',
            onPressed: context.read<SettingsProvider>().toggleTheme,
            icon: const Icon(Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'Business settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQuickActions,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick Add'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: context.tr('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart_rounded),
            label: context.tr('purchase'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.point_of_sale_outlined),
            selectedIcon: const Icon(Icons.point_of_sale_rounded),
            label: context.tr('sales'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2_rounded),
            label: context.tr('stock'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: context.tr('reports'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        minTileHeight: 68,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
