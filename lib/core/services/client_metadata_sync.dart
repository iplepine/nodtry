import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../models/user_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/repository_provider.dart';
import 'app_version_gate.dart' show readInstalledBuildNumber;

/// Keeps `users/{uid}.clientBuild / timezone / locale` current.
///
/// The server needs these to treat old clients safely (e.g. only describe a
/// proof photo to a partner whose build can show it), to judge a missed
/// deadline in the user's own timezone, and to pick push copy. Fields are
/// written only when they differ from the document, and only onto an existing
/// document — `update()`, never `set()`, so a stale cached profile can never
/// resurrect a deleted account as a three-field stub.

/// The app's language as the server should see it: 'ko' or 'en'.
///
/// [override] is the language picked in Settings (null = follow the device);
/// the app supports only ko/en and falls back to en, so does this.
String resolveClientLocale(Locale? override, Locale platformLocale) {
  final code = (override ?? platformLocale).languageCode.toLowerCase();
  return code.startsWith('ko') ? 'ko' : 'en';
}

/// The fields of [profile] that differ from what this client reports.
///
/// Unknown values (null/blank build or timezone) are never written, so a
/// failed platform read cannot erase a good value.
Map<String, Object> clientMetadataUpdates({
  required UserModel profile,
  required int? clientBuild,
  required String? timezone,
  required String locale,
}) {
  final updates = <String, Object>{};
  if (clientBuild != null && profile.clientBuild != clientBuild) {
    updates['clientBuild'] = clientBuild;
  }
  final tz = timezone?.trim();
  if (tz != null && tz.isNotEmpty && profile.timezone != tz) {
    updates['timezone'] = tz;
  }
  if (profile.locale != locale) {
    updates['locale'] = locale;
  }
  return updates;
}

/// The device's IANA timezone id, or null if the platform can't say.
Future<String?> readDeviceTimezone() async {
  final info = await FlutterTimezone.getLocalTimezone();
  return info.identifier;
}

class ClientMetadataSync {
  ClientMetadataSync({
    FirebaseFirestore Function()? firestore,
    String? Function()? currentUid,
    Future<int?> Function()? readClientBuild,
    Future<String?> Function()? readTimezone,
  }) : _firestore = firestore ?? (() => FirebaseFirestore.instance),
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _readClientBuild = readClientBuild ?? readInstalledBuildNumber,
       _readTimezone = readTimezone ?? readDeviceTimezone;

  final FirebaseFirestore Function() _firestore;
  final String? Function() _currentUid;
  final Future<int?> Function() _readClientBuild;
  final Future<String?> Function() _readTimezone;

  /// Platform values are fixed for the life of the process; read them once.
  Future<int?>? _clientBuild;
  Future<String?>? _timezone;

  /// The last update written this session, to skip repeats while the profile
  /// stream catches up with our own write.
  String? _lastWrittenKey;

  Future<int?> _build() =>
      _clientBuild ??= _readClientBuild().catchError((Object _) => null);

  Future<String?> _tz() =>
      _timezone ??= _readTimezone().catchError((Object _) => null);

  /// Writes whatever of build/timezone/[locale] differs from [profile].
  ///
  /// Never throws: this is bookkeeping and must not disturb the app.
  Future<void> syncIfNeeded(UserModel profile, {required String locale}) async {
    try {
      // The profile stream emits a cached profile first; it can belong to a
      // previous account on this device. Only write for the signed-in user.
      if (_currentUid() != profile.uid) return;

      final updates = clientMetadataUpdates(
        profile: profile,
        clientBuild: await _build(),
        timezone: await _tz(),
        locale: locale,
      );
      if (updates.isEmpty) return;

      final key =
          '${profile.uid}:${updates.entries.map((e) => '${e.key}=${e.value}').join(',')}';
      if (key == _lastWrittenKey) return;
      _lastWrittenKey = key;

      await _firestore().collection('users').doc(profile.uid).update(updates);
    } catch (e) {
      // e.g. not-found (no user document yet), offline, no Firebase in tests.
      _lastWrittenKey = null;
      debugPrint('[ClientMetadataSync] skipped: $e');
    }
  }
}

final clientMetadataSyncProvider = Provider<ClientMetadataSync>(
  (ref) => ClientMetadataSync(),
);

/// Watch this once from the app root: it re-syncs whenever the signed-in
/// profile (a user document exists) or the app language changes.
final clientMetadataSyncBinderProvider = Provider<void>((ref) {
  void sync() {
    try {
      final profile = ref.read(myProfileProvider).value;
      if (profile == null) return;
      final locale = resolveClientLocale(
        ref.read(appSettingsProvider).currentLocale,
        PlatformDispatcher.instance.locale,
      );
      unawaited(
        ref
            .read(clientMetadataSyncProvider)
            .syncIfNeeded(profile, locale: locale),
      );
    } catch (e) {
      debugPrint('[ClientMetadataSync] binder skipped: $e');
    }
  }

  ref.listen(myProfileProvider, (_, _) => sync(), fireImmediately: true);
  ref.listen(
    appSettingsProvider.select((s) => s.currentLocale),
    (_, _) => sync(),
  );
});
