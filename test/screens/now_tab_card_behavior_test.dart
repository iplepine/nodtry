import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/application/notification_routing.dart';
import 'package:nod_try/features/now/domain/usecases/get_now_cards_use_case.dart';
import 'package:nod_try/features/now/presentation/now_tab_screen.dart';
import 'package:nod_try/features/plan/domain/usecases/setting_alarm_use_case.dart';
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/features/proof/domain/proof_photo_processing.dart';
import 'package:nod_try/features/proof/presentation/proof_capture.dart';
import 'package:nod_try/features/proof/presentation/proof_photo_view.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/proof_photo.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/services/notification_service.dart';
import 'package:nod_try/widgets/time_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Card behaviour (buttons, chip colours) must come from the card *state*,
/// never from the display copy the repository puts in `headerMessage`.
/// These tests feed the old magic strings back in and expect no effect.

class _FakeRecordRepository extends Fake implements RecordRepository {
  final cheers = <({String planId, String reaction, String? message})>[];
  final downloads = <String>[];

  @override
  Future<List<String>> completeOverduePlans() async => const [];

  @override
  Future<void> cheerPartner(
    String planId,
    String reactionType, {
    String? message,
  }) async {
    cheers.add((planId: planId, reaction: reactionType, message: message));
  }

  @override
  Future<Uint8List?> downloadProofPhoto(String path) async {
    downloads.add(path);
    return _tinyJpeg;
  }

  @override
  Future<HistoryItem?> getHistoryItem(String actionId) async => null;

  final completions =
      <({String planId, String? note, ProofPhotoUpload? photo})>[];

  /// The next report counts as saved offline (no server ack yet).
  bool queued = false;

  @override
  Future<ProofCompletionResult> reportCompletion(
    String planId, {
    String? note,
    ProofPhotoUpload? photo,
  }) async {
    completions.add((planId: planId, note: note, photo: photo));
    return ProofCompletionResult(
      actionId: 'action-new',
      photoPath: photo == null ? null : 'proofs/me/$planId/action-new.jpg',
      attemptedSource: photo?.source,
      queued: queued,
    );
  }

  final skips = <String>[];

  @override
  Future<void> reportSkip(String planId) async => skips.add(planId);
}

final Uint8List _tinyJpeg = img.encodeJpg(img.Image(width: 8, height: 8));

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

Plan _plan({
  String id = 'plan-1',
  String userId = 'partner-uid',
  String? managerId = 'me',
  PlanState state = PlanState.active,
  String title = '헬스장 가기',
  String? description,
  NotificationTime? time,
  String? workoutType,
  List<DateTime> completedDates = const [],
  String? lastActionNote,
  String? lastActionId,
  String? lastProofPhotoPath,
  DateTime? lastProofAt,
  List<DateTime> verifiedDates = const [],
  String? lastCheerType,
}) {
  final now = DateTime.now();
  return Plan(
    verifiedDates: verifiedDates,
    lastCheerType: lastCheerType,
    workoutType: workoutType,
    completedDates: completedDates,
    lastActionNote: lastActionNote,
    lastActionId: lastActionId,
    lastProofPhotoPath: lastProofPhotoPath,
    lastProofAt: lastProofAt,
    id: id,
    userId: userId,
    managerId: managerId,
    startDate: now.subtract(const Duration(days: 1)),
    endDate: now.add(const Duration(days: 20)),
    state: state,
    createdAt: now.subtract(const Duration(days: 1)),
    items: [
      PlanItem(
        title: title,
        days: const [1, 2, 3, 4, 5, 6, 7],
        count: 7,
        description: description,
        notificationTime: time ?? NotificationTime.custom(21, 0),
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
    isSupported: true,
    isCheering: true,
  );
}

Widget _wrap(
  List<HomeCardModel> cards,
  Locale locale, {
  _FakeRecordRepository? repository,
  SharedPreferences? prefs,
}) {
  return ProviderScope(
    overrides: [
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      proofImagePickerProvider.overrideWithValue((_) async => _tinyJpeg),
      proofPhotoProcessorProvider.overrideWithValue(
        (bytes) async => processProofPhotoBytes(bytes),
      ),
      recordRepositoryProvider.overrideWithValue(
        repository ?? _FakeRecordRepository(),
      ),
      getNowCardsUseCaseProvider.overrideWithValue(_FakeGetNowCards(cards)),
      settingAlarmUseCaseProvider.overrideWithValue(
        SettingAlarmUseCase(_FakeScheduler()),
      ),
      connectedProfilesProvider.overrideWith((ref) async => [_partner()]),
      // Memory-only cache: widget tests have no path_provider.
      proofPhotoCacheProvider.overrideWith(
        (ref) => ProofPhotoCache(
          fetch: ref.watch(recordRepositoryProvider).downloadProofPhoto,
          directory: () async => null,
        ),
      ),
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

const _locales = [Locale('ko'), Locale('en')];

void main() {
  for (final locale in _locales) {
    group('[${locale.languageCode}]', () {
      late AppLocalizations l10n;

      setUp(() async {
        l10n = await AppLocalizations.delegate.load(locale);
      });

      for (final magic in const [
        '함께하는 중',
        'Working together',
        '조정 중',
        'Adjusting',
        null,
      ]) {
        testWidgets(
          'a plan proposal shows 조정하기/승인 with headerMessage "$magic"',
          (tester) async {
            await tester.pumpWidget(
              _wrap([
                HomeCardModel(
                  state: HomeCardState.partnerPlanCreate,
                  plan: _plan(state: PlanState.pendingApproval),
                  partnerUid: 'partner-uid',
                  headerMessage: magic,
                ),
              ], locale),
            );
            await tester.pumpAndSettle();

            expect(find.text(l10n.nowApprove), findsOneWidget);
            expect(find.text(l10n.nowAdjust), findsOneWidget);
            expect(
              find.text(l10n.nowPartnerProposed('Jimin')),
              findsOneWidget,
            );
            expect(find.text(l10n.nowPartnerAdjusting), findsNothing);
          },
        );
      }

      testWidgets('a plan change reads as adjusting, whatever its header', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.partnerPlanModify,
              plan: _plan(state: PlanState.pendingApproval),
              partnerUid: 'partner-uid',
              headerMessage: 'Working together',
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.nowPartnerAdjusting), findsOneWidget);
        expect(find.text(l10n.nowApprove), findsOneWidget);
      });

      testWidgets('time chips: overdue is past, a due card is upcoming', (
        tester,
      ) async {
        final now = DateTime.now();
        final soon = now.add(const Duration(minutes: 10));
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.nowAction,
              plan: _plan(
                id: 'mine-now',
                userId: 'me',
                managerId: null,
                time: NotificationTime.custom(soon.hour, soon.minute),
              ),
            ),
            HomeCardModel(
              state: HomeCardState.overdue,
              plan: _plan(
                id: 'mine-overdue',
                userId: 'me',
                managerId: null,
                title: '아침 스트레칭',
                time: NotificationTime.custom(7, 0),
              ),
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        final chips = tester.widgetList<TimeChip>(find.byType(TimeChip));
        final byText = {for (final c in chips) c.text: c.type};
        // The overdue chip says "…지나갔어요/Passed", the due one carries the
        // comforting suffix — neither text decides the type any more.
        expect(byText.values, contains(TimeChipType.past));
        expect(byText.values, contains(TimeChipType.upcoming));
        for (final entry in byText.entries) {
          if (entry.key.contains(l10n.timeChipPassed)) {
            expect(entry.value, TimeChipType.past, reason: entry.key);
          } else {
            expect(entry.value, TimeChipType.upcoming, reason: entry.key);
          }
        }
      });

      testWidgets(
        'an if-then description is shown once and no habit tip is added',
        (tester) async {
          const description = '퇴근하면 바로 헬스장 가기 when I get off work';
          final soon = DateTime.now().add(const Duration(minutes: 10));
          await tester.pumpWidget(
            _wrap([
              HomeCardModel(
                state: HomeCardState.nowAction,
                plan: _plan(
                  userId: 'me',
                  managerId: null,
                  description: description,
                  time: NotificationTime.custom(soon.hour, soon.minute),
                ),
              ),
            ], locale),
          );
          await tester.pumpAndSettle();

          // The "record gaze" tip used to repeat any description containing
          // 하면/되면/나면/when/if right under itself. Its copy keys (nowGuide*)
          // are gone now, so the description must simply appear once.
          expect(find.text(description), findsOneWidget);
          expect(find.textContaining('꾸준함이 힘이에요'), findsNothing);
          expect(find.textContaining('Consistency wins'), findsNothing);
        },
      );

      testWidgets('the focus-timer button is hidden on a due card', (
        tester,
      ) async {
        final soon = DateTime.now().add(const Duration(minutes: 10));
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.nowAction,
              plan: _plan(
                userId: 'me',
                managerId: null,
                workoutType: 'running',
                time: NotificationTime.custom(soon.hour, soon.minute),
              ),
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        // The due card is the check-in hero now: photo first, then no photo.
        expect(find.text(l10n.nowProofTakePhoto), findsOneWidget);
        expect(find.text(l10n.nowDidItNoPhoto), findsOneWidget);
        expect(find.text(l10n.nowStartFocusTimer), findsNothing);
        expect(find.byIcon(Icons.timer_outlined), findsNothing);
      });

      testWidgets(
        'a promise due tonight already asks "오늘 … 했어?" in the morning',
        (tester) async {
          // A nextAction card: isDueNowItem is false this far from 22:00, but
          // the hero is shown all day for a promise scheduled today.
          await tester.pumpWidget(
            _wrap([
              HomeCardModel(
                state: HomeCardState.nextAction,
                plan: _plan(
                  userId: 'me',
                  managerId: null,
                  workoutType: 'running',
                  title: '저녁에 5km 뛰기',
                  time: NotificationTime.custom(22, 0),
                ),
              ),
            ], locale),
          );
          await tester.pumpAndSettle();

          expect(
            find.text(l10n.nowHeroQuestion('🏃', l10n.workoutTypeRunningLabel)),
            findsOneWidget,
          );
          expect(find.text('저녁에 5km 뛰기'), findsOneWidget);
          expect(find.text(l10n.nowProofTakePhoto), findsOneWidget);
          expect(find.text(l10n.nowDidItNoPhoto), findsOneWidget);
          // The rest pass is unused this week.
          expect(find.text(l10n.nowRestToday), findsOneWidget);
          // The old weak "미리 할게 / 오늘 할게" button is gone.
          expect(find.text(l10n.nowDoEarly), findsNothing);
          expect(find.text(l10n.nowDoAnytime), findsNothing);
        },
      );

      testWidgets('a promise from before the pivot asks with its title', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.nextAction,
              plan: _plan(
                userId: 'me',
                managerId: null,
                title: '책 10쪽 읽기',
                time: NotificationTime.custom(22, 0),
              ),
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10n.nowHeroQuestionLegacy('책 10쪽 읽기')),
          findsOneWidget,
        );
        // Not a workout: 인증하기, not a workout-photo prompt (spec §4.4).
        expect(find.text(l10n.nowHeroVerifyLegacy), findsOneWidget);
        expect(find.text(l10n.nowProofTakePhoto), findsNothing);
        expect(find.text(l10n.nowDidItNoPhoto), findsOneWidget);
      });

      testWidgets('an overdue card keeps the same hero buttons', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.overdue,
              plan: _plan(
                userId: 'me',
                managerId: null,
                workoutType: 'gym',
                time: NotificationTime.custom(0, 0),
              ),
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10n.nowHeroQuestion('🏋️', l10n.workoutTypeGymLabel)),
          findsOneWidget,
        );
        expect(find.text(l10n.nowProofTakePhoto), findsOneWidget);
        expect(find.text(l10n.nowDidItNoPhoto), findsOneWidget);
      });

      testWidgets(
        'the rescue button stays hidden even when rescue is possible',
        (tester) async {
          await tester.pumpWidget(
            _wrap([
              HomeCardModel(
                state: HomeCardState.partnerPoke,
                plan: _plan(),
                partnerUid: 'partner-uid',
                canRescue: true,
              ),
            ], locale),
          );
          await tester.pumpAndSettle();

          expect(find.text(l10n.nowKnockPull), findsOneWidget);
          expect(find.text(l10n.nowRescueYesterday), findsNothing);
        },
      );

      testWidgets('a reported workout offers one-tap reactions, no dialog', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.partnerAction,
              plan: _plan(),
              partnerUid: 'partner-uid',
              headerMessage: 'Working together',
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            l10n.nowHeaderConfirmAndPull('Jimin'),
          ),
          findsOneWidget,
        );
        for (final emoji in const ['❤️', '🔥', '💪', '👏']) {
          expect(find.byKey(ValueKey('react-$emoji')), findsOneWidget);
        }
        expect(find.text(l10n.nowReactAddNote), findsOneWidget);
        expect(find.text(l10n.nowVerifyAndCheer), findsNothing);
        expect(find.text(l10n.nowApprove), findsNothing);
      });

      testWidgets('tapping 🔥 gives 인정 with that emoji right away', (
        tester,
      ) async {
        final repository = _FakeRecordRepository();
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.partnerAction,
                plan: _plan(),
                partnerUid: 'partner-uid',
              ),
            ],
            locale,
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('react-🔥')));
        await tester.pump();

        // No keyboard-first dialog in between.
        expect(find.byType(TextField), findsNothing);
        expect(repository.cheers, hasLength(1));
        expect(repository.cheers.single.planId, 'plan-1');
        expect(repository.cheers.single.reaction, '🔥');
        expect(repository.cheers.single.message, isNull);

        await tester.pump();
        expect(find.text(l10n.nowReactedSnackbar('🔥')), findsOneWidget);
      });

      testWidgets('한마디 opens the optional note, sent with ❤️', (tester) async {
        final repository = _FakeRecordRepository();
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.partnerAction,
                plan: _plan(),
                partnerUid: 'partner-uid',
              ),
            ],
            locale,
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('react-add-note')));
        await tester.pumpAndSettle();
        expect(repository.cheers, isEmpty);

        await tester.enterText(find.byType(TextField), '멋지다');
        await tester.tap(find.text(l10n.nowVerifyAndSend));
        await tester.pumpAndSettle();

        expect(repository.cheers.single.reaction, '❤️');
        expect(repository.cheers.single.message, '멋지다');
      });

      testWidgets("the partner's proof photo and note show on the card", (
        tester,
      ) async {
        final repository = _FakeRecordRepository();
        final now = DateTime.now();
        const path = 'proofs/partner-uid/plan-1/action-9.jpg';
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.partnerAction,
                plan: _plan(
                  completedDates: [now],
                  lastActionNote: '하체 끝',
                  lastActionId: 'action-9',
                  lastProofPhotoPath: path,
                  lastProofAt: now,
                ),
                partnerUid: 'partner-uid',
              ),
            ],
            locale,
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProofPhoto), findsOneWidget);
        expect(repository.downloads, [path]);
        expect(find.text('하체 끝'), findsOneWidget);
      });

      testWidgets("yesterday's photo is not shown as today's proof", (
        tester,
      ) async {
        final repository = _FakeRecordRepository();
        final now = DateTime.now();
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.partnerAction,
                plan: _plan(
                  completedDates: [now],
                  // Today's report had no photo: lastActionId moved on.
                  lastActionId: 'action-today',
                  lastProofPhotoPath:
                      'proofs/partner-uid/plan-1/action-old.jpg',
                  lastProofAt: now.subtract(const Duration(days: 1)),
                ),
                partnerUid: 'partner-uid',
              ),
            ],
            locale,
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProofPhoto), findsNothing);
        expect(repository.downloads, isEmpty);
      });

      testWidgets(
        'after reporting, my own proof photo and the partner\'s 인정 show',
        (tester) async {
          final repository = _FakeRecordRepository();
          final now = DateTime.now();
          const path = 'proofs/me/plan-1/action-1.jpg';
          final plan = _plan(
            userId: 'me',
            managerId: 'partner-uid',
            completedDates: [now],
            lastActionId: 'action-1',
            lastProofPhotoPath: path,
            lastProofAt: now,
            verifiedDates: [now],
            lastCheerType: '❤️',
          );
          await tester.pumpWidget(
            _wrap(
              [
                HomeCardModel(
                  state: HomeCardState.todayComplete,
                  plan: plan,
                  completedPlans: [plan],
                ),
              ],
              locale,
              repository: repository,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(ProofPhoto), findsOneWidget);
          expect(repository.downloads, [path]);
          expect(
            find.byKey(const ValueKey('now-partner-verified')),
            findsOneWidget,
          );
          expect(find.text(l10n.historyPartnerVerified), findsOneWidget);
          // No hero once today is recorded.
          expect(find.text(l10n.nowProofTakePhoto), findsNothing);
        },
      );

      testWidgets('hero and reaction row fit a small phone with large text', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.nextAction,
              plan: _plan(
                id: 'mine',
                userId: 'me',
                managerId: null,
                workoutType: 'home_training',
                time: NotificationTime.custom(22, 0),
              ),
            ),
            HomeCardModel(
              state: HomeCardState.partnerAction,
              plan: _plan(),
              partnerUid: 'partner-uid',
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(l10n.nowProofTakePhoto), findsOneWidget);
        expect(find.byKey(const ValueKey('react-❤️')), findsOneWidget);
      });

      testWidgets('📸 인증샷 찍기 → consent → camera → preview → reported', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = _FakeRecordRepository();
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.nextAction,
                plan: _plan(
                  userId: 'me',
                  managerId: 'partner-uid',
                  workoutType: 'gym',
                  time: NotificationTime.custom(22, 0),
                ),
              ),
            ],
            locale,
            repository: repository,
            prefs: prefs,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('now-hero-photo')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('proof-consent-agree')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('proof-source-camera')));
        await tester.pumpAndSettle();

        expect(find.text(l10n.proofPreviewTitle), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('proof-preview-note')),
          '하체 완료',
        );
        await tester.tap(find.byKey(const ValueKey('proof-preview-submit')));
        await tester.pumpAndSettle();

        final report = repository.completions.single;
        expect(report.planId, 'plan-1');
        expect(report.note, '하체 완료');
        expect(report.photo!.source, ProofSource.camera);
        expect(report.photo!.takenAt, isNotNull);
        expect(find.text(l10n.proofUploadDone), findsOneWidget);
      });

      testWidgets('사진 없이 했어 reports without a photo', (tester) async {
        final repository = _FakeRecordRepository();
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.nextAction,
                plan: _plan(
                  userId: 'me',
                  managerId: null,
                  time: NotificationTime.custom(22, 0),
                ),
              ),
            ],
            locale,
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('now-hero-no-photo')));
        await tester.pumpAndSettle();
        // The optional note dialog, then 했어.
        await tester.tap(find.text(l10n.homeDidIt).last);
        await tester.pumpAndSettle();

        expect(repository.completions.single.photo, isNull);
        expect(find.text(l10n.proofUploadDone), findsNothing);
      });

      testWidgets('a record saved offline says it will sync', (tester) async {
        final repository = _FakeRecordRepository()..queued = true;
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.nextAction,
                plan: _plan(
                  userId: 'me',
                  managerId: null,
                  workoutType: 'running',
                  time: NotificationTime.custom(22, 0),
                ),
              ),
            ],
            locale,
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('now-hero-no-photo')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.homeDidIt).last);
        await tester.pumpAndSettle();

        expect(repository.completions, hasLength(1));
        expect(find.text(l10n.nowRecordQueued), findsOneWidget);
        expect(
          find.byKey(const ValueKey('now-recording-progress')),
          findsNothing,
        );
      });

      testWidgets('skipping asks first: it counts as a missed day', (
        tester,
      ) async {
        final repository = _FakeRecordRepository();
        await tester.pumpWidget(
          _wrap(
            [
              HomeCardModel(
                state: HomeCardState.overdue,
                plan: _plan(
                  userId: 'me',
                  managerId: 'partner-uid',
                  workoutType: 'gym',
                  time: NotificationTime.custom(0, 0),
                ),
              ),
            ],
            locale,
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();

        Future<void> openSkip() async {
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();
          // The streak-safe rest pass is offered next to the skip.
          expect(find.byKey(const ValueKey('defer-rest')), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('defer-skip')));
          await tester.pumpAndSettle();
        }

        await openSkip();
        expect(find.text(l10n.nowSkipDialogTitle), findsOneWidget);
        expect(
          find.text(l10n.nowSkipDialogBody('헬스장 가기')),
          findsOneWidget,
        );
        await tester.tap(find.text(l10n.nowCancel));
        await tester.pumpAndSettle();
        expect(repository.skips, isEmpty);

        await openSkip();
        await tester.tap(find.text(l10n.nowSkipToday));
        await tester.pumpAndSettle();
        expect(repository.skips, ['plan-1']);
      });

      testWidgets('an opened reminder offers the photo check-in first', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.nextAction,
              plan: _plan(
                userId: 'me',
                managerId: null,
                workoutType: 'running',
                time: NotificationTime.custom(22, 0),
              ),
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        ProviderScope.containerOf(
          tester.element(find.byType(NowTab)),
        ).read(nowCheckInRequestProvider.notifier).request('plan-1');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('check-in-sheet-photo')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('check-in-sheet-no-photo')),
          findsOneWidget,
        );
        // Not the old note-only dialog.
        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('a knock on my card names the partner', (tester) async {
        final now = DateTime.now();
        await tester.pumpWidget(
          _wrap([
            HomeCardModel(
              state: HomeCardState.poked,
              plan: _plan(
                userId: 'me',
                managerId: 'partner-uid',
                workoutType: 'running',
              ).copyWith(lastPokeAt: now),
              headerMessage: '똑똑! 오늘 약속 기다리고 있어',
            ),
          ], locale),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.nowPokeReceivedFromName('Jimin')), findsOneWidget);
        expect(find.text(l10n.nowPokeReceived), findsNothing);
      });
    });
  }
}
