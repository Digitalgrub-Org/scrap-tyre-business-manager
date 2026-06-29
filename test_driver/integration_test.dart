import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

// Saves screenshots captured by the integration test into the fastlane folder,
// where `fastlane upload_screenshots` (deliver) picks them up automatically.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String name,
      List<int> bytes, [
      Map<String, Object?>? args,
    ]) async {
      final file = File('fastlane/screenshots/en-US/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
