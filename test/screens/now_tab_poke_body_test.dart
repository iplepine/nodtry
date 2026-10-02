import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/domain/usecases/get_now_cards_use_case.dart';
import 'package:nod_try/features/now/presentation/now_tab_screen.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/services/notification_service.dart';

class _FakeRecordRepository extends Fake implements RecordRepository {
  @override
  Future<List<String>> completeOverduePlans() async => const [];
}

class _FakeGetNowCards extends Fake implements GetNowCardsUseCase {
  _FakeGetNowCards(this.cards);

  final List<HomeCardModel> cards;

  @override
  Stream<List<HomeCardModel>> executeStream() => Stream.value(cards);
}

class _FakeScheduler implements PlanReminderScheduler {
  @override
  Future<void> cancelPlanReminders(int planId) async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> schedulePlanReminder({
    required int planId,
    String? planIdentifier,
    required String title,
    String? body,
    required int hour,
    required int minute,
    required List<int> days,
    bool skipToday = false,
    int intervalHours = 0,
    int startHour = 0,
    int endHour = 0,
  }) async {}
}

Plan _plan() {
  final now = DateTime.now();
  return Plan(
    id: 'plan-1',
    userId: 'partner-uid',
    managerId: 'me',
    startDate: now.subtract(const Duration(days: 1)),
    endDate: now.add(const Duration(days: 7)),
    state: PlanState.active,
    createdAt: now.subtract(const Duration(days: 1)),
    items: [
      PlanItem(
        title: '아침 영양제 챙겨먹기',
        days: const [1, 2, 3, 4, 5, 6, 7],
        count: 7,
        notificationTime: NotificationTime.custom(9, 0),
      ),
    ],
  );
}

ConnectedUser _partner() {
  final now = DateTime.now();
  return ConnectedUser(
    user: UserModel(
      uid: 'partner-uid',
      displayName: 'Jimin',
      createdAt: now,
      updatedAt: now,
    ),
    isSupported: false,
    isCheering: true,
  );
}

Widget _wrap({required bool hasMissedNotice, required Locale locale}) {
  final card = HomeCardModel(
    state: HomeCardState.partnerPoke,
    plan: _plan(),
    partnerUid: 'partner-uid',
    // The repository ships a *translated* sentence here. The card must not use
    // it to decide anything.
    headerMessage: hasMissedNotice
        ? (locale.languageCode == 'ko'
              ? '놓친 약속이 떴어요'
              : 'A missed promise appeared')
        : (locale.languageCode == 'ko' ? '똑똑 보낼 차례' : 'Time to send a knock'),
    hasMissedNotice: hasMissedNotice,
  );

  return ProviderScope(
    overrides: [
      recordRepositoryProvider.overrideWithValue(_FakeRecordRepository()),
      getNowCardsUseCaseProvider.overrideWithValue(_FakeGetNowCards([card])),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(_FakeScheduler()),
      ),
      connectedProfilesProvider.overrideWith((ref) async => [_partner()]),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NowTab()),
    ),
  );
}

void main() {
  testWidgets('an English missed-promise knock shows the missed body', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(hasMissedNotice: true, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.text(l10n.nowPartnerMissedPokeBody('Jimin')),
      findsOneWidget,
      reason: 'expected the missed-promise body for hasMissedNotice: true',
    );
    expect(find.text(l10n.nowPartnerQuietPokeBody('Jimin')), findsNothing);
  });

  testWidgets('an English quiet knock still shows the quiet body', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(hasMissedNotice: false, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.nowPartnerQuietPokeBody('Jimin')), findsOneWidget);
    expect(find.text(l10n.nowPartnerMissedPokeBody('Jimin')), findsNothing);
  });

  testWidgets('the Korean missed-promise knock keeps working', (tester) async {
    await tester.pumpWidget(
      _wrap(hasMissedNotice: true, locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.text(l10n.nowPartnerMissedPokeBody('Jimin')), findsOneWidget);
    // Particle-safe copy: the name is never followed by 님.
    expect(find.textContaining('Jimin님'), findsNothing);
  });
}
