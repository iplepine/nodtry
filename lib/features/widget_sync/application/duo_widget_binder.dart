import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/repository_provider.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../duo/application/duo_stats_provider.dart';
import '../domain/duo_widget_snapshot.dart';
import 'widget_sync_service.dart';

/// What the home-screen widget should show right now.
class DuoWidgetTarget {
  const DuoWidgetTarget._(this.snapshot, {required this.keep});

  /// Still loading: leave whatever the widget shows.
  static const keepCurrent = DuoWidgetTarget._(null, keep: true);

  /// Signed out or no partner: remove the data.
  static const cleared = DuoWidgetTarget._(null, keep: false);

  const DuoWidgetTarget.show(DuoWidgetSnapshot this.snapshot) : keep = false;

  final DuoWidgetSnapshot? snapshot;
  final bool keep;

  @override
  bool operator ==(Object other) =>
      other is DuoWidgetTarget &&
      other.keep == keep &&
      other.snapshot == snapshot;

  @override
  int get hashCode => Object.hash(keep, snapshot);
}

final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  final service = WidgetSyncService(const HomeWidgetDuoStore());
  ref.onDispose(service.dispose);
  return service;
});

/// The widget copy's language: the Settings choice, else the device's.
AppLocalizations _widgetL10n(Locale? chosen) {
  final code =
      chosen?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(code.startsWith('ko') ? 'ko' : 'en'));
}

/// The widget's target, recomputed whenever the duo stats, the partner's
/// label, the account or the language change.
final duoWidgetTargetProvider = Provider.autoDispose<DuoWidgetTarget>((ref) {
  final auth = ref.watch(authStateChangesProvider);
  if (auth.isLoading && !auth.hasValue) return DuoWidgetTarget.keepCurrent;
  final uid = auth.value?.uid;
  if (uid == null) return DuoWidgetTarget.cleared;

  final partners = ref.watch(connectedProfilesProvider);
  if (!partners.hasValue) return DuoWidgetTarget.keepCurrent;
  final label = ref.watch(partnerLabelProvider);
  if (!label.hasPartner) return DuoWidgetTarget.cleared;

  final stats = ref.watch(duoStatsProvider);
  final myPlans = ref.watch(myDuoPlansProvider);
  final partnerPlans = ref.watch(duoPlansProvider(label.partnerUid!)).value;
  if (stats == null || myPlans == null || partnerPlans == null) {
    return DuoWidgetTarget.keepCurrent;
  }

  final l10n = _widgetL10n(
    ref.watch(appSettingsProvider.select((s) => s.currentLocale)),
  );
  final snapshot = buildDuoWidgetSnapshot(
    stats: stats,
    myPlans: myPlans,
    partnerPlans: partnerPlans,
    partnerName: label.resolve(l10n),
    l10n: l10n,
  );
  return snapshot == null
      ? DuoWidgetTarget.cleared
      : DuoWidgetTarget.show(snapshot);
});

/// Keeps the home-screen / lock-screen widgets in step with the duo header:
/// a write whenever the target changes (a record, a 인정, a new day, the
/// partner's nickname, the language), a forced redraw on app resume, and a
/// clear on sign-out or disconnect. Watched once from the app root.
final duoWidgetBinderProvider = Provider<void>((ref) {
  final service = ref.watch(widgetSyncServiceProvider);

  void apply(DuoWidgetTarget target, {bool force = false}) {
    if (target.keep) return;
    service.push(target.snapshot, force: force);
  }

  ref.listen<DuoWidgetTarget>(
    duoWidgetTargetProvider,
    (previous, next) => apply(next),
    fireImmediately: true,
  );

  try {
    final lifecycle = AppLifecycleListener(
      onResume: () {
        // The device language may have changed in the background; recompute,
        // then redraw even when nothing changed.
        ref.invalidate(duoWidgetTargetProvider);
        apply(ref.read(duoWidgetTargetProvider), force: true);
      },
    );
    ref.onDispose(lifecycle.dispose);
  } catch (_) {
    // No widgets binding (plain provider tests).
  }
});
