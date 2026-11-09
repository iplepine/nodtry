/// The home-screen / lock-screen widget's data (iOS WidgetKit, Android
/// AppWidget): a small, already-localized snapshot of the duo header.
///
/// The native widgets can't run Dart, read Firestore or reach the ARB copy,
/// so the app renders every string here and saves one JSON document under
/// [kDuoWidgetSnapshotKey] in the shared widget storage (iOS App Group
/// `UserDefaults`, Android `HomeWidgetPreferences`). The native side only
/// lays it out, and swaps both statuses for [DuoWidgetSnapshot.staleText]
/// once its [DuoWidgetSnapshot.date] is no longer today.
///
/// Privacy: names and status words only — no photos, notes, messages or
/// promise text. Lock-screen widgets show on a locked device.
library;

import 'dart:convert';

import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';
import '../../duo/domain/duo_stats.dart';

/// Shared-storage key of the JSON snapshot. The native widgets read the same
/// key (ios/DuoWidget/DuoWidget.swift, android DuoWidgetProvider.kt).
const String kDuoWidgetSnapshotKey = 'duo_widget_snapshot_v1';

/// Bumped only for an incompatible layout of the JSON; fields are added
/// optionally otherwise.
const int kDuoWidgetSnapshotVersion = 1;

/// One person's today, as the widget shows it.
enum DuoWidgetPersonStatus {
  /// Recorded (no photo, or only a photo-less 했어).
  done('done'),

  /// Recorded with a proof photo today (the 인증샷 itself is never shared).
  doneWithProof('done_proof'),

  /// Covered by a rest pass / rescue only.
  rested('rest'),

  /// Scheduled and still open.
  pending('pending'),

  /// Nothing scheduled today.
  notScheduled('off');

  const DuoWidgetPersonStatus(this.wire);

  /// The value stored in the JSON (native code switches on it for icons).
  final String wire;
}

class DuoWidgetPerson {
  const DuoWidgetPerson({
    required this.name,
    required this.status,
    required this.statusText,
  });

  /// "나" / "Me", or the partner's label (nickname → display name → 짝꿍).
  final String name;
  final DuoWidgetPersonStatus status;

  /// Localized [status].
  final String statusText;

  Map<String, Object?> toJson() => {
    'name': name,
    'status': status.wire,
    'text': statusText,
  };

  @override
  bool operator ==(Object other) =>
      other is DuoWidgetPerson &&
      other.name == name &&
      other.status == status &&
      other.statusText == statusText;

  @override
  int get hashCode => Object.hash(name, status, statusText);
}

class DuoWidgetSnapshot {
  const DuoWidgetSnapshot({
    required this.date,
    required this.streak,
    required this.headline,
    required this.duoDoneToday,
    required this.badge,
    required this.me,
    required this.partner,
    required this.staleText,
    required this.locale,
  });

  /// The day this snapshot describes, `yyyy-MM-dd` (local).
  final String date;

  /// Consecutive 둘운완 days up to today.
  final int streak;

  /// "둘이 함께 N일째" / "Together N days" (or the streak-0 line).
  final String headline;

  final bool duoDoneToday;

  /// "오늘 둘운완이에요 🎉" when [duoDoneToday], else null.
  final String? badge;

  final DuoWidgetPerson me;
  final DuoWidgetPerson partner;

  /// Shown instead of the statuses once [date] has passed.
  final String staleText;

  /// `ko` / `en`.
  final String locale;

  /// The JSON the native widgets read. [updatedAt] is left out of equality
  /// so an unchanged snapshot isn't written again.
  Map<String, Object?> toJson({DateTime? updatedAt}) => {
    'v': kDuoWidgetSnapshotVersion,
    'date': date,
    'streak': streak,
    'headline': headline,
    'duoDone': duoDoneToday,
    'badge': badge,
    'me': me.toJson(),
    'partner': partner.toJson(),
    'stale': staleText,
    'locale': locale,
    if (updatedAt != null) 'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  String encode({DateTime? updatedAt}) =>
      jsonEncode(toJson(updatedAt: updatedAt));

  @override
  bool operator ==(Object other) =>
      other is DuoWidgetSnapshot && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;

  @override
  String toString() => 'DuoWidgetSnapshot(${encode()})';
}

/// `yyyy-MM-dd` of [day] (local), the format the native widgets compare.
String duoWidgetDateKey(DateTime day) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-${two(day.month)}-'
      '${two(day.day)}';
}

/// Today's [DuoWidgetPersonStatus] for one person from their [day] in the
/// duo stats and their [plans] (for the proof photo).
DuoWidgetPersonStatus duoWidgetStatusOf(
  DuoPersonDay day,
  List<Plan> plans,
  DateTime today,
) {
  switch (day.status) {
    case DuoDayStatus.done:
      return _hasProofOn(plans, today)
          ? DuoWidgetPersonStatus.doneWithProof
          : DuoWidgetPersonStatus.done;
    case DuoDayStatus.rested:
      return DuoWidgetPersonStatus.rested;
    case DuoDayStatus.pending:
    // Not reachable for today; treated as still open rather than "missed",
    // which the widget never says.
    case DuoDayStatus.missed:
    case DuoDayStatus.upcoming:
      return DuoWidgetPersonStatus.pending;
    case DuoDayStatus.off:
      return DuoWidgetPersonStatus.notScheduled;
  }
}

/// A 했어 with a photo was reported today on one of [plans]: the plan's last
/// proof is from today and today is recorded.
bool _hasProofOn(List<Plan> plans, DateTime today) {
  for (final plan in plans) {
    final proofAt = plan.lastProofAt;
    final path = plan.lastProofPhotoPath;
    if (proofAt == null || path == null || path.isEmpty) continue;
    if (!_sameDay(proofAt, today)) continue;
    if (plan.completedDates.any((d) => _sameDay(d, today))) return true;
  }
  return false;
}

bool _sameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

String duoWidgetStatusText(
  DuoWidgetPersonStatus status,
  AppLocalizations l10n,
) {
  return switch (status) {
    DuoWidgetPersonStatus.done => l10n.homeWidgetStatusDone,
    DuoWidgetPersonStatus.doneWithProof => l10n.homeWidgetStatusDoneProof,
    DuoWidgetPersonStatus.rested => l10n.homeWidgetStatusRested,
    DuoWidgetPersonStatus.pending => l10n.homeWidgetStatusPending,
    DuoWidgetPersonStatus.notScheduled => l10n.homeWidgetStatusOff,
  };
}

/// The widget snapshot for [stats], or null when there is nothing to show
/// (no partner: the widget then shows its own "open the app" placeholder).
///
/// [partnerName] is the resolved partner label (nickname → display name →
/// 짝꿍, see `PartnerLabel.resolve`).
DuoWidgetSnapshot? buildDuoWidgetSnapshot({
  required DuoStats? stats,
  required List<Plan> myPlans,
  required List<Plan> partnerPlans,
  required String partnerName,
  required AppLocalizations l10n,
}) {
  if (stats == null || !stats.hasPartner) return null;
  final today = stats.today.date;
  final meStatus = duoWidgetStatusOf(stats.today.me, myPlans, today);
  final partnerStatus = duoWidgetStatusOf(
    stats.today.partner,
    partnerPlans,
    today,
  );
  final duoDone = stats.todayIsDuoDone;
  return DuoWidgetSnapshot(
    date: duoWidgetDateKey(today),
    streak: stats.streak,
    headline: stats.streak > 0
        ? l10n.homeWidgetStreak(stats.streak)
        : l10n.homeWidgetStreakZero,
    duoDoneToday: duoDone,
    badge: duoDone ? l10n.homeWidgetTodayDuoDone : null,
    me: DuoWidgetPerson(
      name: l10n.homeWidgetMe,
      status: meStatus,
      statusText: duoWidgetStatusText(meStatus, l10n),
    ),
    partner: DuoWidgetPerson(
      name: partnerName,
      status: partnerStatus,
      statusText: duoWidgetStatusText(partnerStatus, l10n),
    ),
    staleText: l10n.homeWidgetStale,
    locale: l10n.localeName.startsWith('ko') ? 'ko' : 'en',
  );
}
