import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/business_provider.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 2) {
      await context.read<BusinessProvider>().completeOnboarding();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: const [
                    _WelcomePage(),
                    _WorkflowPage(),
                    _DemoPage(),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 7,
                    width: index == _page ? 26 : 7,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? AppTheme.green
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _next,
                child: Text(_page == 2 ? 'Start Testing' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.storefront_rounded,
      color: AppTheme.navy,
      title: 'Welcome to your business manager',
      description:
          'Track scrap tyre purchases, sales, stock, expenses and profit in '
          'one offline app designed for fast daily entry.',
      children: const [
        _GuidePoint(
          icon: Icons.dashboard_outlined,
          text: 'Dashboard shows today\'s position at a glance.',
        ),
        _GuidePoint(
          icon: Icons.wifi_off_rounded,
          text: 'Records stay on this device and work offline.',
        ),
      ],
    );
  }
}

class _WorkflowPage extends StatelessWidget {
  const _WorkflowPage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.playlist_add_check_circle_rounded,
      color: AppTheme.green,
      title: 'How to test the workflow',
      description:
          'Use the bottom navigation or Quick Add button. Start by recording '
          'incoming stock, then record a sale and expenses.',
      children: const [
        _GuidePoint(
          number: '1',
          text: 'Purchase increases item quantity and weight.',
        ),
        _GuidePoint(number: '2', text: 'Sales reduce available stock safely.'),
        _GuidePoint(
          number: '3',
          text: 'Expenses and reports update net profit.',
        ),
      ],
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.science_outlined,
      color: AppTheme.orange,
      title: 'Demo data is included',
      description:
          'Sample purchases, sales and expenses help you explore the '
          'dashboard. A visible banner lets you clear only demo entries '
          'before entering real records.',
      children: const [
        _GuidePoint(
          icon: Icons.settings_outlined,
          text: 'Use Settings to enter your shop details.',
        ),
        _GuidePoint(
          icon: Icons.delete_sweep_outlined,
          text: 'Clear Demo Data will not delete your new entries.',
        ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 30),
        Container(
          height: 86,
          width: 86,
          margin: const EdgeInsets.only(bottom: 26),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 42, color: color),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 26),
        ...children,
      ],
    );
  }
}

class _GuidePoint extends StatelessWidget {
  const _GuidePoint({this.icon, this.number, required this.text});

  final IconData? icon;
  final String? number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.green.withValues(alpha: 0.12),
              foregroundColor: AppTheme.green,
              child: icon != null
                  ? Icon(icon, size: 19)
                  : Text(
                      number!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
