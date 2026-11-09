import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/application/partner_label_provider.dart';
import 'package:nod_try/features/duo/application/duo_stats_provider.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/features/proof/presentation/proof_photo_view.dart';
import 'package:nod_try/features/together/application/together_providers.dart';
import 'package:nod_try/features/together/presentation/together_widgets.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/services/notification_service.dart';
import 'package:nod_try/widgets/action_note_dialog.dart';

class _Records extends Fake implements RecordRepository {
  final confirms = <({String planId, String sourceActionId})>[];
  TogetherConfirmOutcome outcome = TogetherConfirmOutcome.logged;
  HistoryItem? sourceAction;

  @override
  Future<TogetherConfirmResult> confirmTogether(
    String planId, {
    required String sourceActionId,
  }) async {
    confirms.add((planId: planId, sourceActionId: sourceActionId));
    return TogetherConfirmResult(outcome, actionId: 'b1');
  }

  @override
  Future<HistoryItem?> getHistoryItem(String actionId) async => sourceAction;
}

class _Reminders implements PlanReminderScheduler {
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
    List<DateTime>? onlyDates,
  }) async {}
}

final _now = DateTime(2026, 11, 11, 19);

Plan _plan(String id, String userId, {TogetherMark? lastTogether}) => Plan(
  id: id,
  userId: userId,
  startDate: DateTime(2026, 11, 2),
  endDate: DateTime(2026, 11, 29),
  state: PlanState.active,
  items: [
    PlanItem(title: '헬스', days: const [3], count: 1),
  ],
  createdAt: DateTime(2026, 11, 1),
  workoutType: 'gym',
  lastActionId: lastTogether?.actionId,
  lastTogether: lastTogether,
);

void main() {
  late _Records records;

  setUp(() => records = _Records());

  Widget app(Widget child, {List overrides = const []}) => ProviderScope(
    overrides: [
      recordRepositoryProvider.overrideWithValue(records),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(_Reminders()),
      ),
      myDuoPlansProvider.overrideWithValue(null),
      partnerLabelProvider.overrideWithValue(
        const PartnerLabel(partnerUid: 'partner', nickname: '자기'),
      ),
      togetherClockProvider.overrideWithValue(() => _now),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  group('나도 했어 card', () {
    final claim = TogetherClaim(
      sourcePlan: _plan(
        'theirs',
        'partner',
        lastTogether: TogetherMark(
          actionId: 'a1',
          withUid: 'me',
          planId: 'mine',
          at: _now,
        ),
      ),
      myPlan: _plan('mine', 'me'),
    );

    testWidgets('names the partner and logs only on my tap', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      await tester.pumpWidget(
        app(
          const TogetherClaimCards(),
          overrides: [
            togetherClaimsProvider.overrideWithValue([claim]),
          ],
        ),
      );
      expect(find.text('🤝 자기가 같이 했대요'), findsOneWidget);
      expect(find.text(l10n.togetherClaimConfirm), findsOneWidget);
      // Consent: nothing is logged until I tap.
      expect(records.confirms, isEmpty);

      await tester.tap(find.byKey(const ValueKey('together-claim-confirm')));
      await tester.pumpAndSettle();
      expect(records.confirms.single.planId, 'mine');
      expect(records.confirms.single.sourceActionId, 'a1');
      expect(find.text(l10n.togetherConfirmedSnack), findsOneWidget);
    });

    testWidgets('a stale claim says so instead of logging', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      records.outcome = TogetherConfirmOutcome.unavailable;
      await tester.pumpWidget(
        app(
          const TogetherClaimCards(),
          overrides: [
            togetherClaimsProvider.overrideWithValue([claim]),
          ],
        ),
      );
      await tester.tap(find.byKey(const ValueKey('together-claim-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.togetherUnavailableSnack), findsOneWidget);
    });

    testWidgets('shows nothing without a claim', (tester) async {
      await tester.pumpWidget(
        app(
          const TogetherClaimCards(),
          overrides: [togetherClaimsProvider.overrideWithValue(const [])],
        ),
      );
      expect(find.byType(TogetherClaimCard), findsNothing);
    });
  });

  group('같이 했어 toggle', () {
    const tag = TogetherTag(partnerUid: 'partner', partnerPlanId: 'theirs');

    testWidgets('is off by default and selects the offered plan when on', (
      tester,
    ) async {
      final choice = TogetherChoice();
      await tester.pumpWidget(
        app(
          ActionNoteDialog(
            title: '헬스',
            showEmoji: false,
            footer: TogetherToggle(planId: 'mine', choice: choice),
          ),
          overrides: [togetherTargetProvider('mine').overrideWithValue(tag)],
        ),
      );
      expect(find.text('🤝 자기랑 같이 했어'), findsOneWidget);
      expect(choice.offered?.partnerPlanId, 'theirs');
      expect(choice.selection, isNull);

      await tester.tap(find.byKey(const ValueKey('together-toggle')));
      await tester.pump();
      expect(choice.selection?.partnerPlanId, 'theirs');
      expect(choice.selection?.partnerUid, 'partner');
    });

    testWidgets('is hidden when nothing of the partner is due', (tester) async {
      final choice = TogetherChoice()..value = true;
      await tester.pumpWidget(
        app(
          TogetherToggle(planId: 'mine', choice: choice),
          overrides: [togetherTargetProvider('mine').overrideWithValue(null)],
        ),
      );
      expect(find.byKey(const ValueKey('together-toggle')), findsNothing);
      expect(choice.selection, isNull);
    });
  });

  group('a shared photo its owner deleted', () {
    const path = 'proofs/partner/theirs/a1.jpg';

    List overrides(Future<Uint8List?> Function(String) fetch) => [
      proofPhotoCacheProvider.overrideWithValue(
        ProofPhotoCache(fetch: fetch, directory: () async => null),
      ),
    ];

    testWidgets('shows nothing rather than an error', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      // The object is gone and the record no longer points at it.
      records.sourceAction = null;
      await tester.pumpWidget(
        app(
          const ProofPhoto(path: path, hideWhenUnavailable: true),
          overrides: overrides((_) async => null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.proofPhotoLoadFailed), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cached copy goes away once the record drops it', (
      tester,
    ) async {
      final cache = ProofPhotoCache(
        fetch: (_) async => Uint8List.fromList([1, 2, 3]),
        directory: () async => null,
      );
      await cache.load(path);
      expect(cache.peek(path), isNotNull);
      records.sourceAction = HistoryItem(
        id: 'a1',
        date: _now,
        title: '헬스',
        status: HistoryStatus.done,
        executorId: 'partner',
      );
      await tester.pumpWidget(
        app(
          const ProofPhoto(path: path, hideWhenUnavailable: true),
          overrides: [proofPhotoCacheProvider.overrideWithValue(cache)],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(cache.peek(path), isNull);
    });

    testWidgets('my own photo still shows the retry box', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      await tester.pumpWidget(
        app(
          const ProofPhoto(path: path),
          overrides: overrides((_) async => null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.proofPhotoLoadFailed), findsOneWidget);
    });
  });
}
