import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/duo_widget_snapshot.dart';

/// iOS App Group shared by Runner and the WidgetKit extension
/// (Runner.entitlements / DuoWidgetExtension.entitlements).
const String kDuoWidgetAppGroupId = 'group.com.devho.nodtry.app';

/// The WidgetKit `kind` of the iOS widget (ios/DuoWidget/DuoWidget.swift).
const String kDuoWidgetIosKind = 'DuoWidget';

/// The Android AppWidgetProviders (android/app/src/main/kotlin/…/widget).
const List<String> kDuoWidgetAndroidProviders = [
  'com.devho.nodtry.app.widget.DuoWidgetSmallProvider',
  'com.devho.nodtry.app.widget.DuoWidgetMediumProvider',
];

/// Where the snapshot goes. [HomeWidgetDuoStore] in the app; a fake in
/// tests.
abstract class DuoWidgetStore {
  /// Saves [json] under [kDuoWidgetSnapshotKey]; null removes it.
  Future<void> write(String? json);

  /// Asks the OS to redraw the widgets from the stored data.
  Future<void> reloadWidgets();
}

/// The real store: home_widget's shared storage (App Group `UserDefaults` on
/// iOS, `HomeWidgetPreferences` on Android).
class HomeWidgetDuoStore implements DuoWidgetStore {
  const HomeWidgetDuoStore();

  @override
  Future<void> write(String? json) async {
    await HomeWidget.saveWidgetData<String>(
      kDuoWidgetSnapshotKey,
      json,
      appGroupId: kDuoWidgetAppGroupId,
    );
  }

  @override
  Future<void> reloadWidgets() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.updateWidget(iOSName: kDuoWidgetIosKind);
      return;
    }
    for (final provider in kDuoWidgetAndroidProviders) {
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
    }
  }
}

/// Writes the widget snapshot, deduped and throttled.
///
/// - The same snapshot is never written twice in a row (unless forced, e.g.
///   on app resume to make the OS redraw).
/// - At most one write per [minInterval]; changes in between are coalesced
///   and only the latest is written when the interval is up.
/// - [clear] removes the data (sign-out, disconnect); the widgets then show
///   their own "open the app" placeholder.
///
/// Failures (no plugin in tests, no App Group on a misconfigured build) are
/// logged and swallowed: the widget is a nicety and must never break the app.
class WidgetSyncService {
  WidgetSyncService(
    this._store, {
    this.minInterval = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DuoWidgetStore _store;
  final Duration minInterval;
  final DateTime Function() _clock;

  /// What is in storage now: [_unknown] until the first write, `null` when
  /// cleared, else the encoded snapshot (without `updatedAt`).
  Object? _written = _unknown;
  static const Object _unknown = Object();

  /// The latest request not written yet.
  bool _hasPending = false;
  DuoWidgetSnapshot? _pending;
  bool _pendingForce = false;

  DateTime? _lastWriteAt;
  Timer? _timer;
  bool _writing = false;
  bool _disposed = false;

  /// Number of writes that reached the store (tests / debugging).
  @visibleForTesting
  int writeCount = 0;

  /// Shows [snapshot] on the widgets (null = [clear]).
  void push(DuoWidgetSnapshot? snapshot, {bool force = false}) {
    if (_disposed) return;
    final encoded = snapshot?.encode();
    if (!force && !_hasPending && _writtenEquals(encoded)) return;
    _hasPending = true;
    _pending = snapshot;
    _pendingForce = _pendingForce || force;
    _schedule();
  }

  /// Removes the snapshot (signed out / no partner).
  void clear() => push(null);

  bool _writtenEquals(String? encoded) =>
      !identical(_written, _unknown) && _written == encoded;

  void _schedule() {
    if (_timer != null || _writing) return;
    final last = _lastWriteAt;
    final wait = last == null
        ? Duration.zero
        : minInterval - _clock().difference(last);
    if (wait <= Duration.zero) {
      unawaited(_flush());
    } else {
      _timer = Timer(wait, () {
        _timer = null;
        unawaited(_flush());
      });
    }
  }

  Future<void> _flush() async {
    if (_disposed || !_hasPending) return;
    final snapshot = _pending;
    final force = _pendingForce;
    _hasPending = false;
    _pending = null;
    _pendingForce = false;

    final encoded = snapshot?.encode();
    if (!force && _writtenEquals(encoded)) return;

    _writing = true;
    _lastWriteAt = _clock();
    try {
      await _store.write(snapshot?.encode(updatedAt: _clock()));
      _written = encoded;
      writeCount++;
      await _store.reloadWidgets();
    } catch (e) {
      // Leave [_written] as it was so the next change retries.
      debugPrint('[WidgetSync] write failed: $e');
    } finally {
      _writing = false;
    }
    if (_hasPending && !_disposed) _schedule();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
