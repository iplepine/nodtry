import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/repository_provider.dart';
import '../../theme/app_colors.dart';

/// Minimum-version gate.
///
/// At startup the app reads `config/app {minBuild, latestBuild}` once (public
/// read, written only from the console / admin). A build below `minBuild` gets
/// a blocking "업데이트가 필요해요" page; a build below `latestBuild` gets a soft
/// prompt once per `latestBuild`. Any failure — no Firebase, offline, the doc
/// missing, rules not deployed yet, a slow read past [kAppVersionCheckTimeout]
/// — means no gate: the gate must never be the reason the app won't open.

/// Play Store listing for `com.devho.nodtry.app`.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.devho.nodtry.app';

/// App Store listing (track id 6761373605 from the iTunes lookup for bundle
/// `com.devho.nodtry.app`).
const String kAppStoreUrl = 'https://apps.apple.com/kr/app/id6761373605';

/// How long the startup check may take before the app goes on without it.
const Duration kAppVersionCheckTimeout = Duration(seconds: 3);

/// SharedPreferences key: the `latestBuild` whose soft prompt was dismissed.
const String kSoftUpdateDismissedBuildKey = 'app.soft_update_dismissed_build';

/// What the running build has to do about updating.
enum AppUpdateRequirement {
  /// Nothing — up to date, or the check could not run.
  none,

  /// A newer build exists; suggest it once.
  soft,

  /// This build is below the supported minimum; block until updated.
  required,
}

/// `config/app` as read from Firestore. Both fields are optional.
@immutable
class AppVersionConfig {
  final int? minBuild;
  final int? latestBuild;

  const AppVersionConfig({this.minBuild, this.latestBuild});

  /// Lenient parse: numbers or numeric strings; anything else is ignored.
  factory AppVersionConfig.fromMap(Map<String, dynamic>? map) {
    return AppVersionConfig(
      minBuild: _parseBuild(map?['minBuild']),
      latestBuild: _parseBuild(map?['latestBuild']),
    );
  }

  static int? _parseBuild(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

/// Compares the running [currentBuild] with the remote [config].
///
/// An unknown build or a missing value never gates.
AppUpdateRequirement evaluateAppUpdate({
  required int? currentBuild,
  required AppVersionConfig config,
}) {
  if (currentBuild == null) return AppUpdateRequirement.none;
  final minBuild = config.minBuild;
  if (minBuild != null && currentBuild < minBuild) {
    return AppUpdateRequirement.required;
  }
  final latestBuild = config.latestBuild;
  if (latestBuild != null && currentBuild < latestBuild) {
    return AppUpdateRequirement.soft;
  }
  return AppUpdateRequirement.none;
}

/// Whether the soft prompt for [status] is still due, given the `latestBuild`
/// the user last dismissed it for.
bool shouldShowSoftUpdatePrompt(
  AppVersionStatus status, {
  required int? dismissedForBuild,
}) {
  if (status.requirement != AppUpdateRequirement.soft) return false;
  return status.latestBuild != null && status.latestBuild != dismissedForBuild;
}

/// Result of the startup check.
@immutable
class AppVersionStatus {
  final AppUpdateRequirement requirement;
  final int? currentBuild;
  final int? latestBuild;

  const AppVersionStatus({
    required this.requirement,
    this.currentBuild,
    this.latestBuild,
  });

  static const AppVersionStatus unknown = AppVersionStatus(
    requirement: AppUpdateRequirement.none,
  );
}

/// Reads the running build number and `config/app`, never throwing.
class AppVersionGateService {
  AppVersionGateService({
    FirebaseFirestore Function()? firestore,
    Future<int?> Function()? readCurrentBuild,
    this.timeout = kAppVersionCheckTimeout,
  }) : _firestore = firestore ?? (() => FirebaseFirestore.instance),
       _readCurrentBuild = readCurrentBuild ?? readInstalledBuildNumber;

  final FirebaseFirestore Function() _firestore;
  final Future<int?> Function() _readCurrentBuild;
  final Duration timeout;

  Future<AppVersionStatus> check() async {
    try {
      // Resolve Firestore first: without a Firebase app this throws at once,
      // before any timer is started.
      final firestore = _firestore();
      final results = await Future.wait<Object?>([
        _readCurrentBuild(),
        firestore.collection('config').doc('app').get(),
      ]).timeout(timeout);
      final currentBuild = results[0] as int?;
      final snapshot = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final config = AppVersionConfig.fromMap(snapshot.data());
      return AppVersionStatus(
        requirement: evaluateAppUpdate(
          currentBuild: currentBuild,
          config: config,
        ),
        currentBuild: currentBuild,
        latestBuild: config.latestBuild,
      );
    } catch (e) {
      debugPrint('[AppVersionGate] check skipped: $e');
      return AppVersionStatus.unknown;
    }
  }
}

/// The installed build number (`version: x.y.z+BUILD`), or null if unknown.
Future<int?> readInstalledBuildNumber() async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber.trim());
}

/// The store page for this platform.
String storeUrlForPlatform(TargetPlatform platform) {
  return platform == TargetPlatform.iOS ? kAppStoreUrl : kPlayStoreUrl;
}

final appVersionGateServiceProvider = Provider<AppVersionGateService>(
  (ref) => AppVersionGateService(),
);

/// Checked at launch, and again when the app comes back to the foreground
/// ([shouldRecheckAppVersion]) — a `minBuild` raised while the app sat in the
/// background, or a launch check that timed out, would otherwise last until
/// the OS killed the process.
final appVersionStatusProvider = FutureProvider<AppVersionStatus>((ref) {
  return ref.watch(appVersionGateServiceProvider).check();
});

/// Re-check at most this often on resume (always after an unknown result).
const Duration kAppVersionRecheckInterval = Duration(minutes: 30);

/// Whether a resume should re-run the version check: the last result is
/// unknown (failed / timed out / none yet) or older than
/// [kAppVersionRecheckInterval].
bool shouldRecheckAppVersion({
  required AppVersionStatus? last,
  required DateTime? lastCheckedAt,
  required DateTime now,
}) {
  // Unknown: the check failed or timed out (no build was read).
  if (last == null ||
      identical(last, AppVersionStatus.unknown) ||
      last.currentBuild == null) {
    return true;
  }
  if (lastCheckedAt == null) return true;
  return now.difference(lastCheckedAt) >= kAppVersionRecheckInterval;
}

/// Opens the store page; overridable in tests.
final openStorePageProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    try {
      return await launchUrl(
        Uri.parse(storeUrlForPlatform(defaultTargetPlatform)),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('[AppVersionGate] store launch failed: $e');
      return false;
    }
  };
});

/// Wraps the routed app (via `MaterialApp.builder`) with the version gate.
///
/// It sits outside the router, so the redirect flow is untouched: while the
/// check runs, or when it fails, [child] shows as usual.
class AppVersionGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppVersionGate({super.key, required this.child});

  @override
  ConsumerState<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends ConsumerState<AppVersionGate>
    with WidgetsBindingObserver {
  bool _softDismissed = false;
  DateTime? _checkedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (!shouldRecheckAppVersion(
      last: ref.read(appVersionStatusProvider).value,
      lastCheckedAt: _checkedAt,
      now: now,
    )) {
      return;
    }
    _checkedAt = now;
    // The previous result stays visible while the new check runs.
    ref.invalidate(appVersionStatusProvider);
  }

  int? _dismissedForBuild() {
    try {
      return ref
          .read(sharedPreferencesProvider)
          .getInt(kSoftUpdateDismissedBuildKey);
    } catch (_) {
      return null;
    }
  }

  void _dismissSoft(int? latestBuild) {
    setState(() => _softDismissed = true);
    if (latestBuild == null) return;
    try {
      unawaited(
        ref
            .read(sharedPreferencesProvider)
            .setInt(kSoftUpdateDismissedBuildKey, latestBuild),
      );
    } catch (_) {
      // Not persisted: the prompt may show again next launch. Harmless.
    }
  }

  Future<void> _openStore() async {
    final opened = await ref.read(openStorePageProvider)();
    if (!opened && mounted) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n.appUpdateStoreOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appVersionStatusProvider).value;
    if (status == null) return widget.child;

    if (status.requirement == AppUpdateRequirement.required) {
      return _UpdateRequiredPage(onUpdate: _openStore);
    }

    final showSoft =
        !_softDismissed &&
        shouldShowSoftUpdatePrompt(
          status,
          dismissedForBuild: _dismissedForBuild(),
        );
    if (!showSoft) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: _SoftUpdatePrompt(
            onUpdate: () {
              _dismissSoft(status.latestBuild);
              unawaited(_openStore());
            },
            onLater: () => _dismissSoft(status.latestBuild),
          ),
        ),
      ],
    );
  }
}

/// Full-screen block for builds below `minBuild`. No way past it but the store.
class _UpdateRequiredPage extends StatelessWidget {
  final VoidCallback onUpdate;

  const _UpdateRequiredPage({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.system_update_rounded,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.appUpdateRequiredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appUpdateRequiredBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onUpdate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.appUpdateButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-time suggestion for builds below `latestBuild`.
///
/// Drawn in the app's builder layer (above the router), so it is a plain
/// overlay rather than a route dialog.
class _SoftUpdatePrompt extends StatelessWidget {
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const _SoftUpdatePrompt({required this.onUpdate, required this.onLater});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.appUpdateSoftTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.appUpdateSoftBody,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: onUpdate,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.appUpdateButton),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: onLater,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text(l10n.appUpdateLater),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
