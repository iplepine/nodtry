import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/core/services/app_version_gate.dart';
import 'package:nod_try/features/connect/domain/invite_code.dart';
import 'package:nod_try/features/connect/domain/partner_label.dart';
import 'package:nod_try/features/now/application/notification_routing.dart';
import 'package:nod_try/features/now/presentation/cards/check_in_question.dart';
import 'package:nod_try/features/now/presentation/cards/now_card_rules.dart';
import 'package:nod_try/features/now/presentation/promise/active_promise_chip.dart';
import 'package:nod_try/features/plan/application/reminder_copy_refresh.dart';
import 'package:nod_try/features/plan/domain/workout_template.dart';
import 'package:nod_try/features/plan/presentation/widgets/plan_schedule_pickers.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/promise_model.dart';
import 'package:nod_try/services/notification_service.dart';
import 'package:nod_try/utils/ui_error_codes.dart';

Plan _plan({
  String id = 'p1',
  String? managerId = 'partner',
  String? workoutType,
  NotificationTime? time,
  PlanState state = PlanState.active,
}) {
  final now = DateTime(2026, 10, 2);
  return Plan(
    id: id,
    userId: 'me',
    managerId: managerId,
    startDate: now.subtract(const Duration(days: 3)),
    endDate: now.add(const Duration(days: 24)),
    state: state,
    createdAt: now,
    workoutType: workoutType,
    items: [
      PlanItem(
        title: '러닝 30분',
        days: const [1, 2, 3, 4, 5, 6, 7],
        count: 7,
        notificationTime: time,
      ),
    ],
  );
}

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;

  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('opened notifications go to their screen', () {
    test('reminders and knocks open the check-in', () {
      expect(
        notificationOpenTargetFor(NotificationOpenRequest.reminderType),
        NotificationOpenTarget.nowCheckIn,
      );
      expect(
        notificationOpenTargetFor('poke'),
        NotificationOpenTarget.nowCheckIn,
      );
    });

    test('partner pushes route by type; unknown types do nothing', () {
      for (final type in [
        'poke_reply',
        'action_completed',
        'action_missed',
        'action_verified',
        'cheer',
      ]) {
        expect(
          notificationOpenTargetFor(type),
          NotificationOpenTarget.now,
          reason: type,
        );
      }
      expect(
        notificationOpenTargetFor('verify_reminder'),
        NotificationOpenTarget.history,
      );
      expect(
        notificationOpenTargetFor('partner_connected'),
        NotificationOpenTarget.us,
      );
      expect(
        notificationOpenTargetFor('partner_connect_failed'),
        NotificationOpenTarget.connect,
      );
      expect(
        notificationOpenTargetFor('something_new'),
        NotificationOpenTarget.none,
      );
    });

    test('a push data map becomes a request', () {
      final request = NotificationOpenRequest.fromData({
        'type': 'partner_connect_failed',
        'reason': 'owner_taken',
        'planId': '',
      })!;
      expect(request.type, 'partner_connect_failed');
      expect(request.reason, 'owner_taken');
      expect(request.planId, isNull);
      expect(NotificationOpenRequest.fromData({'title': 'x'}), isNull);
    });

    test('a failure reason maps to its own explanation', () {
      expect(
        ConnectErrorCode.forFailureReason('owner_taken'),
        ConnectErrorCode.ownerTaken,
      );
      expect(
        ConnectErrorCode.forFailureReason('self_taken'),
        ConnectErrorCode.selfTaken,
      );
      expect(
        ConnectErrorCode.forFailureReason('invalid_code'),
        ConnectErrorCode.codeChanged,
      );
      expect(
        ConnectErrorCode.forFailureReason(null),
        ConnectErrorCode.linkUndone,
      );
    });
  });

  group('the overdue chip says how late it is', () {
    final plan = _plan(time: NotificationTime.custom(7, 0));

    test('minutes, then hours', () {
      expect(
        overdueTimeChipText(ko, plan, now: DateTime(2026, 10, 2, 7, 40)),
        '40분 지남',
      );
      expect(
        overdueTimeChipText(ko, plan, now: DateTime(2026, 10, 2, 22, 5)),
        '15시간 지남',
      );
      expect(
        overdueTimeChipText(en, plan, now: DateTime(2026, 10, 2, 22, 5)),
        '15h ago',
      );
    });

    test('no deadline: just passed', () {
      expect(
        overdueTimeChipText(ko, _plan(), now: DateTime(2026, 10, 2, 9)),
        ko.timeChipPassed,
      );
    });
  });

  group('못 지키면 counts missed days, like the settlement', () {
    final penalty = PromisePenalty(description: '🍗 치킨 쏘기', targetDays: 2);

    test('the bet is on once the misses reach the target', () {
      expect(penaltyMissesLeft(penalty, failed: 0), 2);
      expect(penaltyMissesLeft(penalty, failed: 1), 1);
      expect(penaltyMissesLeft(penalty, failed: 2), 0);
    });

    test('the copy says how many more misses set it off', () {
      expect(ko.promiseChipSafePenaltyOnly(2, '🍗'), '2번 더 놓치면 — 🍗');
      expect(
        en.promiseChipSafePenaltyOnly(2, '🍗'),
        "2 more misses and it's 🍗",
      );
      expect(ko.planDetailPromisePenaltyBuffer(3), '3번 더 놓치면 내기 확정');
    });
  });

  group('clipboard codes', () {
    test('a link, the code alone or the invite message', () {
      expect(
        findInviteCodeInClipboardText('https://nod-try.web.app/i/K7MP2QXR'),
        'K7MP2QXR',
      );
      expect(findInviteCodeInClipboardText('  K7MP2QXR '), 'K7MP2QXR');
      expect(
        findInviteCodeInClipboardText('둘운완 깔고 코드 K7MP2QXR 넣으면 바로 연결돼'),
        'K7MP2QXR',
      );
    });

    test('any other 8-letter token is never looked up', () {
      expect(
        findInviteCodeInClipboardText('복구 코드: AB12CD34 (보관하세요)'),
        isNull,
      );
      expect(findInviteCodeInClipboardText('password K7MP2QXR'), isNull);
      expect(findInviteCodeInClipboardText('20261003'), isNull);
    });
  });

  group('the old "나" / "Me" placeholder is no partner name', () {
    test('falls back to 짝꿍', () {
      expect(isPlaceholderDisplayName('나'), isTrue);
      expect(isPlaceholderDisplayName(' Me '), isTrue);
      expect(isPlaceholderDisplayName('나연'), isFalse);
      expect(
        resolvePartnerLabel(displayName: '나', fallback: '짝꿍'),
        '짝꿍',
      );
      const label = PartnerLabel(partnerUid: 'p', displayName: 'Me');
      expect(label.preferred, isNull);
      expect(label.preferredFor('p'), isNull);
      expect(
        const PartnerLabel(
          partnerUid: 'p',
          nickname: '자기',
          displayName: '나',
        ).preferred,
        '자기',
      );
    });
  });

  group('the deadline the partner notice waits for', () {
    test('a daily reminder fires before the deadline (alertOffset)', () {
      // "1시간 전" before 21:00 stores 20:00 + 60.
      expect(
        NotificationTime.custom(20, 0, alertOffset: 60).deadlineMinutes,
        21 * 60,
      );
      expect(NotificationTime.custom(21, 30).deadlineMinutes, 21 * 60 + 30);
    });

    test('hourly runs until the end hour; off has no deadline', () {
      expect(
        NotificationTime.hourly(
          intervalHours: 3,
          startHour: 9,
          endHour: 21,
        ).deadlineMinutes,
        21 * 60,
      );
      expect(NotificationTime.none().deadlineMinutes, isNull);
    });
  });

  group('version re-check on resume', () {
    final now = DateTime(2026, 10, 3, 9);
    const known = AppVersionStatus(
      requirement: AppUpdateRequirement.none,
      currentBuild: 81,
      latestBuild: 81,
    );

    test('always after an unknown result', () {
      expect(
        shouldRecheckAppVersion(
          last: AppVersionStatus.unknown,
          lastCheckedAt: now,
          now: now,
        ),
        isTrue,
      );
      expect(
        shouldRecheckAppVersion(last: null, lastCheckedAt: null, now: now),
        isTrue,
      );
    });

    test('otherwise at most every 30 minutes', () {
      expect(
        shouldRecheckAppVersion(
          last: known,
          lastCheckedAt: now.subtract(const Duration(minutes: 10)),
          now: now,
        ),
        isFalse,
      );
      expect(
        shouldRecheckAppVersion(
          last: known,
          lastCheckedAt: now.subtract(const Duration(minutes: 31)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('reminder copy follows the link', () {
    test('the key changes with the manager and the partner name', () {
      final solo = reminderCopyKey([_plan(managerId: null)], PartnerLabel.none);
      final linked = reminderCopyKey(
        [_plan()],
        const PartnerLabel(partnerUid: 'partner', displayName: '지민'),
      );
      final nicknamed = reminderCopyKey(
        [_plan()],
        const PartnerLabel(
          partnerUid: 'partner',
          nickname: '자기',
          displayName: '지민',
        ),
      );
      expect(solo, isNot(linked));
      expect(linked, isNot(nicknamed));
      expect(reminderCopyKey(null, PartnerLabel.none), isNull);
      // Finished plans don't matter.
      expect(
        reminderCopyKey([
          _plan(managerId: null),
          _plan(id: 'old', state: PlanState.completed),
        ], PartnerLabel.none),
        solo,
      );
    });
  });

  group('workout names inside a sentence', () {
    test('자전거 takes 타기; Strength reads as training', () {
      expect(
        todayCheckInQuestion(ko, _plan(workoutType: 'cycling')),
        '오늘 🚴 자전거 타기 했어?',
      );
      expect(
        todayCheckInQuestion(en, _plan(workoutType: 'strength')),
        en.nowHeroQuestion('💪', 'Strength training'),
      );
      // The tiles keep their short labels.
      expect(workoutTypeLabel(ko, WorkoutType.cycling), '자전거');
    });
  });

  group('time copy', () {
    test('the deadline summary uses the chip names', () {
      expect(
        planDeadlineLabel(ko, NotificationTime.custom(21, 0)),
        ko.planDeadlineNight,
      );
      expect(
        planDeadlineLabel(ko, NotificationTime.custom(20, 30)),
        '오후 8시 30분',
      );
    });

    test('English puts the hour first and counts properly', () {
      expect(planTimeLabel(en, NotificationTime.custom(21, 0)), '9 PM');
      expect(planTimeLabel(en, NotificationTime.custom(20, 30)), '8:30 PM');
      expect(en.planDayCountFormat(1), '1 day/week');
      expect(en.planDayCountFormat(3), '3 days/week');
      expect(en.nowMetricCountSuffix(1), '1 time');
      expect(en.frequencyEveryday, 'Every day');
    });
  });
}
