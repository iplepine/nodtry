// Smoke test: the app builds and renders its first screen without provider /
// dependency-injection errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nod_try/main.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/mock_record_repository.dart';

void main() {
  testWidgets('App launches without provider errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // OnMyBehalfApp -> appSettingsProvider reads SharedPreferences, which
          // is an unimplemented provider until overridden.
          sharedPreferencesProvider.overrideWithValue(prefs),
          recordRepositoryProvider.overrideWithValue(MockRecordRepository()),
        ],
        child: const OnMyBehalfApp(),
      ),
    );
    await tester.pump();

    // The router builds a MaterialApp and the app comes up without throwing.
    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
