import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/business_provider.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (provider.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(provider.error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (!provider.hasCompletedOnboarding) {
      return const OnboardingScreen();
    }
    return const HomeShell();
  }
}
