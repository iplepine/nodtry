import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nod_try/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final screenshotDir = '${Directory.current.path}/ios/fastlane/screenshots/ko';

  Future<void> saveScreenshot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    // Use the binding's screenshot method for iOS
    final List<int> bytes = await binding.takeScreenshot(name);
    final file = File('$screenshotDir/$name.png');
    await file.writeAsBytes(bytes);
    debugPrint('Screenshot saved: ${file.path}');
  }

  testWidgets('App Store screenshots', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Screenshot whatever current screen is
    await saveScreenshot(tester, '02_home');

    // Try to find tabs
    final historyTab = find.text('기록');
    if (historyTab.evaluate().isNotEmpty) {
      await tester.tap(historyTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await saveScreenshot(tester, '03_history');
    }

    final usTab = find.text('우리');
    if (usTab.evaluate().isNotEmpty) {
      await tester.tap(usTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await saveScreenshot(tester, '04_us');
    }
  });
}
