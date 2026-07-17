import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/providers/notification_permission_provider.dart';
import 'package:nod_try/widgets/notification_permission_banner.dart';

Widget _wrap(bool? permission) {
  return ProviderScope(
    overrides: [
      // null → still-unknown (loading); non-null → resolved permission state.
      notificationPermissionProvider.overrideWith((ref) async {
        if (permission == null) {
          // Never completes: keeps the provider in the loading state.
          return Completer<bool>().future;
        }
        return permission;
      }),
    ],
    child: const MaterialApp(
      locale: Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: NotificationPermissionBanner()),
    ),
  );
}

void main() {
  testWidgets('shows the warning banner when notifications are off', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(false));
    await tester.pumpAndSettle();

    expect(find.text('알림이 꺼져 있어요'), findsOneWidget);
    expect(find.text('켜기'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });

  testWidgets('renders nothing when notifications are granted', (tester) async {
    await tester.pumpWidget(_wrap(true));
    await tester.pumpAndSettle();

    expect(find.text('알림이 꺼져 있어요'), findsNothing);
    expect(find.byType(SizedBox), findsWidgets); // SizedBox.shrink()
  });

  testWidgets('renders nothing while permission is still unknown (no flash)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(null));
    await tester.pump(); // let the loading state settle without completing

    expect(find.text('알림이 꺼져 있어요'), findsNothing);
  });
}
