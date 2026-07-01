import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:scrap_tyre_business_manager/app.dart';
import 'package:scrap_tyre_business_manager/firebase_options.dart';
import 'package:scrap_tyre_business_manager/providers/business_provider.dart';
import 'package:scrap_tyre_business_manager/providers/settings_provider.dart';

// Drives the real app on a booted simulator and captures App Store screenshots
// straight from the widget tree (no OS level taps needed). Run with:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart -d <simulator-udid>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture store screenshots', (tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Guest sign in so the app proceeds past the login screen.
    await FirebaseAuth.instance.signInAnonymously();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ],
        child: const ScrapTyreApp(),
      ),
    );

    // Wait for the user's data to finish loading (onboarding or home shell appears).
    await _waitFor(
      tester,
      () =>
          find.byType(NavigationBar).evaluate().isNotEmpty ||
          find.text('Continue').evaluate().isNotEmpty ||
          find.text('Start Testing').evaluate().isNotEmpty,
    );

    // Required on iOS before screenshots can be taken.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // Complete the 3 page onboarding if it is showing.
    for (var i = 0; i < 3; i++) {
      if (find.text('Continue').evaluate().isNotEmpty) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    }
    if (find.text('Start Testing').evaluate().isNotEmpty) {
      await tester.tap(find.text('Start Testing'));
      await tester.pumpAndSettle();
    }

    await _waitFor(
      tester,
      () => find.byType(NavigationBar).evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();

    await _shoot(tester, binding, '02_dashboard');
    await _tapTabAndShoot(tester, binding, Icons.shopping_cart_outlined, '03_purchase');
    await _tapTabAndShoot(tester, binding, Icons.point_of_sale_outlined, '04_sales');
    await _tapTabAndShoot(tester, binding, Icons.inventory_2_outlined, '05_stock');
    await _tapTabAndShoot(tester, binding, Icons.bar_chart_outlined, '06_reports');
  });
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100; i++) {
    if (ready()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shoot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}

Future<void> _tapTabAndShoot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  IconData icon,
  String name,
) async {
  final tab = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byIcon(icon),
  );
  if (tab.evaluate().isNotEmpty) {
    await tester.tap(tab.first);
    await tester.pumpAndSettle();
  }
  await _shoot(tester, binding, name);
}
