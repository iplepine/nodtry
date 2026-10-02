import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/plan_model.dart';
import '../../../providers/repository_provider.dart';
import '../../../repositories/record_repository.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../duo/application/duo_stats_provider.dart' show myDuoPlansProvider;
import '../domain/usecases/setting_alarm_use_case.dart';

/// The pivot build (spec §9 `PIVOT_BUILD`). Reminders scheduled by older
/// builds still carry the old copy (the promise line as title, "오늘 약속,
/// 잊지 않았죠?" as body) for up to four weeks ahead, so every plan reminder is
/// rescheduled once with the new copy after upgrading.
const int kReminderCopyVersion = 81;

/// SharedPreferences key: the [kReminderCopyVersion] the reminders were last
/// rescheduled for.
const String kReminderCopyVersionKey = 'notif.reminder_copy_version';

/// Whether reminders scheduled for [refreshedVersion] still need the
/// one-time reschedule.
bool shouldRefreshReminderCopy(int? refreshedVersion) =>
    refreshedVersion == null || refreshedVersion < kReminderCopyVersion;

/// Reschedules a user's plan reminders once per [kReminderCopyVersion].
class ReminderCopyRefresher {
  ReminderCopyRefresher({
    required SharedPreferences prefs,
    required RecordRepository records,
    required SettingAlarmUseCase alarms,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _records = records,
       _alarms = alarms,
       _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final RecordRepository _records;
  final SettingAlarmUseCase _alarms;
  final DateTime Function() _clock;

  static final Set<String> _inFlight = {};

  /// Reschedules [userId]'s running plans' reminders unless that was already
  /// done for this copy version. Today's reminder is left out for a plan that
  /// already has a record today. Returns whether it rescheduled anything.
  ///
  /// The flag is set only after a pass that found plans: a failed or empty
  /// read (offline, signed out mid-way) is retried on the next launch.
  Future<bool> runIfNeeded(String userId) async {
    if (!shouldRefreshReminderCopy(_prefs.getInt(kReminderCopyVersionKey))) {
      return false;
    }
    if (!_inFlight.add(userId)) return false;
    try {
      final plans = await _records.getPlansByUserId(userId);
      final running = plans.where((p) => p.state == PlanState.active).toList();
      if (running.isEmpty) return false;
      final now = _clock();
      for (final plan in running) {
        await _alarms.execute(plan, skipToday: planHasRecordOn(plan, now));
      }
      await _prefs.setInt(kReminderCopyVersionKey, kReminderCopyVersion);
      return true;
    } catch (e) {
      debugPrint('[ReminderCopyRefresher] reschedule failed (retry later): $e');
      return false;
    } finally {
      _inFlight.remove(userId);
    }
  }
}

/// Runs the one-time reminder reschedule once the signed-in user and their
/// partner list are known (the reminder names the partner). Must stay
/// `ref.watch`-ed from the app root (main.dart).
final reminderCopyRefreshBinderProvider = Provider<void>((ref) {
  final uid = ref.watch(myProfileProvider.select((p) => p.value?.uid));
  if (uid == null) return;
  final partners = ref.watch(connectedProfilesProvider);
  if (!partners.hasValue && !partners.hasError) return;

  final SharedPreferences prefs;
  try {
    prefs = ref.read(sharedPreferencesProvider);
  } catch (_) {
    return; // no SharedPreferences (tests)
  }
  if (!shouldRefreshReminderCopy(prefs.getInt(kReminderCopyVersionKey))) {
    return;
  }
  final refresher = ReminderCopyRefresher(
    prefs: prefs,
    records: ref.read(recordRepositoryProvider),
    alarms: ref.read(settingAlarmUseCaseProvider),
  );
  unawaited(refresher.runIfNeeded(uid));
});

/// What a running plan's reminder copy depends on: its partner (managerId)
/// and what the partner is called. A change after the first value means the
/// queued reminders (up to four weeks) say the wrong thing.
@visibleForTesting
String? reminderCopyKey(List<Plan>? myPlans, PartnerLabel label) {
  if (myPlans == null) return null;
  final running =
      myPlans
          .where((p) => p.state == PlanState.active && p.id != null)
          .map((p) => '${p.id}:${p.managerId ?? '-'}')
          .toList()
        ..sort();
  return '${label.partnerUid ?? '-'}|${label.preferred ?? '-'}|'
      '${running.join(',')}';
}

/// Keeps queued reminders in step with the couple link: after a link the
/// server gives running solo plans a manager (the "곧 {애칭}한테 알려져요"
/// line is missing until rescheduled); after an unlink it clears them (the
/// line promises a notice nobody sends); a new nickname renames the partner.
/// Reschedules every running plan when that changes — after the plans stream
/// reflects the server's managerId change, not on the link event itself,
/// which races the Cloud Function. Must stay `ref.watch`-ed from the app
/// root (main.dart).
final reminderLinkRefreshBinderProvider = Provider<void>((ref) {
  String? lastKey;
  Timer? debounce;
  ref.onDispose(() => debounce?.cancel());

  void check() {
    final partners = ref.read(connectedProfilesProvider);
    if (partners.isLoading && !partners.hasValue) return;
    final plans = ref.read(myDuoPlansProvider);
    final key = reminderCopyKey(plans, ref.read(partnerLabelProvider));
    if (key == null) return;
    final previous = lastKey;
    lastKey = key;
    if (previous == null || previous == key) return;

    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), () async {
      try {
        final current = ref.read(myDuoPlansProvider) ?? const <Plan>[];
        final alarms = ref.read(settingAlarmUseCaseProvider);
        final now = DateTime.now();
        for (final plan in current.where((p) => p.state == PlanState.active)) {
          await alarms.execute(plan, skipToday: planHasRecordOn(plan, now));
        }
      } catch (e) {
        debugPrint('[ReminderLinkRefresh] reschedule skipped: $e');
      }
    });
  }

  ref.listen(myDuoPlansProvider, (_, _) => check());
  ref.listen(partnerLabelProvider, (_, _) => check());
  ref.listen(connectedProfilesProvider, (_, _) => check());
  check();
});
