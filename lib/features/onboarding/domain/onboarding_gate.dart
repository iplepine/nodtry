/// Who sees which first-run step, and the device flags behind it.
///
/// The rules are pure functions so they can be tested without widgets; the
/// [OnboardingStore] keeps the flags in SharedPreferences.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/repository_provider.dart';

/// Accounts created before this day used the app before it became 둘운완.
final DateTime kPivotCutoff = DateTime(2026, 10, 2);

/// SharedPreferences keys owned by onboarding and the invite loop.
class OnboardingPrefKeys {
  OnboardingPrefKeys._();

  /// 'legacy' or 'new' — written once, on the first run of the pivot build.
  static const deviceCohort = 'pivot.device_cohort_v1';
  static const pivotNoticeSeen = 'pivot.notice_seen_v1';
  static const inviteStepDone = 'onboarding.invite_step_done_v1';

  /// Set by the tutorial's "초대 코드 받았어요" link (or an invite link) so
  /// the first screen after login is code entry.
  static const pendingCodeEntry = 'onboarding.pending_code_entry_v1';
  static const pendingInviteCode = 'onboarding.pending_invite_code_v1';
  static const pendingInviteSource = 'onboarding.pending_invite_source_v1';

  /// The once-after-first-login clipboard look for an invite code ran.
  static const clipboardChecked = 'invite.clipboard_checked_v1';

  /// Last time this device shared an invite (millis since epoch).
  static const inviteLastSharedAt = 'invite.last_shared_at_v1';

  /// Partner uid the nickname sheet was last offered for.
  static const nicknamePromptedFor = 'nickname.prompted_partner_v1';

  /// The "약속 걸었어, 봐줘" invite was offered after a first solo promise.
  static const invitePromptedAfterPlan = 'invite.prompted_after_plan_v1';
}

/// Keys older builds wrote. Finding either on the first run of the pivot
/// build means the app was used before.
const String kLegacyTutorialKey = 'nodtry_tutorial_completed_v1';
const String kLegacyCachedProfileKey = 'cached_user_profile';

enum DeviceCohort {
  /// The app ran on this device before the pivot build.
  legacy('legacy'),

  /// First run on this device is the pivot build (or later).
  fresh('new');

  const DeviceCohort(this.id);
  final String id;

  static DeviceCohort? fromId(String? id) {
    for (final cohort in DeviceCohort.values) {
      if (cohort.id == id) return cohort;
    }
    return null;
  }
}

/// The cohort for a device: what was recorded, else whether an older build
/// left its tutorial flag or a cached profile behind.
DeviceCohort resolveDeviceCohort({
  String? stored,
  required bool hadTutorialFlag,
  required bool hadCachedProfile,
}) {
  final known = DeviceCohort.fromId(stored);
  if (known != null) return known;
  return hadTutorialFlag || hadCachedProfile
      ? DeviceCohort.legacy
      : DeviceCohort.fresh;
}

/// Records the device cohort on the first run of this build. Must run before
/// the tutorial or sign-in write their own flags, i.e. at app start.
DeviceCohort recordDeviceCohort(SharedPreferences prefs) {
  final cohort = resolveDeviceCohort(
    stored: prefs.getString(OnboardingPrefKeys.deviceCohort),
    hadTutorialFlag: prefs.getBool(kLegacyTutorialKey) ?? false,
    hadCachedProfile: prefs.containsKey(kLegacyCachedProfileKey),
  );
  if (prefs.getString(OnboardingPrefKeys.deviceCohort) == null) {
    prefs.setString(OnboardingPrefKeys.deviceCohort, cohort.id);
  }
  return cohort;
}

/// Used the app before it became 둘운완: on this device, or with this account.
bool isLegacyUser({
  required DeviceCohort cohort,
  DateTime? accountCreatedAt,
  DateTime? cutoff,
}) {
  if (cohort == DeviceCohort.legacy) return true;
  if (accountCreatedAt == null) return false;
  return accountCreatedAt.isBefore(cutoff ?? kPivotCutoff);
}

/// The "그래,해봐가 둘운완이 됐어요" notice: once, existing users only.
bool shouldShowPivotNotice({
  required bool legacyUser,
  required bool seenOnDevice,
  bool? seenOnAccount,
}) {
  return legacyUser && !seenOnDevice && seenOnAccount != true;
}

enum PostLoginRoute { home, inviteStep, codeEntry }

/// Where a just-signed-in user lands.
///
/// * Someone with a partner goes home.
/// * Someone who said they got a code goes straight to code entry.
/// * A new user without a partner sees the invite step once (it can be
///   skipped with "나중에 초대할게요"). Existing users never do; they get the
///   invite card on the Now tab instead.
/// * [hasPartner] null means "not known yet": the invite step itself leaves
///   for home if a partner turns up.
PostLoginRoute postLoginRoute({
  required bool legacyUser,
  required bool inviteStepDone,
  required bool pendingCodeEntry,
  bool? hasPartner,
}) {
  if (hasPartner == true) return PostLoginRoute.home;
  if (pendingCodeEntry) return PostLoginRoute.codeEntry;
  if (legacyUser || inviteStepDone) return PostLoginRoute.home;
  return PostLoginRoute.inviteStep;
}

/// The one clipboard look after the first login: new users with no partner,
/// once per device.
bool shouldRunPostLoginClipboardCheck({
  required bool legacyUser,
  required bool alreadyChecked,
  required bool? hasPartner,
}) {
  return !legacyUser && !alreadyChecked && hasPartner == false;
}

/// Offer the nickname sheet once per partner, while no nickname is set.
bool shouldPromptNickname({
  required String? partnerUid,
  required String? nickname,
  required String? promptedFor,
}) {
  if (partnerUid == null) return false;
  if (nickname != null && nickname.trim().isNotEmpty) return false;
  return promptedFor != partnerUid;
}

/// Device flags for onboarding and the invite loop.
class OnboardingStore {
  OnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  DeviceCohort get deviceCohort => resolveDeviceCohort(
    stored: _prefs.getString(OnboardingPrefKeys.deviceCohort),
    hadTutorialFlag: _prefs.getBool(kLegacyTutorialKey) ?? false,
    hadCachedProfile: _prefs.containsKey(kLegacyCachedProfileKey),
  );

  /// [isLegacyUser] for this device and [accountCreatedAt].
  bool legacyUser({DateTime? accountCreatedAt}) =>
      isLegacyUser(cohort: deviceCohort, accountCreatedAt: accountCreatedAt);

  bool get pivotNoticeSeen =>
      _prefs.getBool(OnboardingPrefKeys.pivotNoticeSeen) ?? false;
  Future<void> markPivotNoticeSeen() =>
      _prefs.setBool(OnboardingPrefKeys.pivotNoticeSeen, true);

  bool get inviteStepDone =>
      _prefs.getBool(OnboardingPrefKeys.inviteStepDone) ?? false;
  Future<void> markInviteStepDone() =>
      _prefs.setBool(OnboardingPrefKeys.inviteStepDone, true);

  bool get pendingCodeEntry =>
      _prefs.getBool(OnboardingPrefKeys.pendingCodeEntry) ?? false;
  String? get pendingInviteCode =>
      _prefs.getString(OnboardingPrefKeys.pendingInviteCode);
  String? get pendingInviteSource =>
      _prefs.getString(OnboardingPrefKeys.pendingInviteSource);

  Future<void> setPendingCodeEntry({String? code, String? source}) async {
    await _prefs.setBool(OnboardingPrefKeys.pendingCodeEntry, true);
    if (code != null) {
      await _prefs.setString(OnboardingPrefKeys.pendingInviteCode, code);
    }
    if (source != null) {
      await _prefs.setString(OnboardingPrefKeys.pendingInviteSource, source);
    }
  }

  Future<void> clearPendingCodeEntry() async {
    await _prefs.remove(OnboardingPrefKeys.pendingCodeEntry);
    await _prefs.remove(OnboardingPrefKeys.pendingInviteCode);
    await _prefs.remove(OnboardingPrefKeys.pendingInviteSource);
  }

  bool get clipboardChecked =>
      _prefs.getBool(OnboardingPrefKeys.clipboardChecked) ?? false;
  Future<void> markClipboardChecked() =>
      _prefs.setBool(OnboardingPrefKeys.clipboardChecked, true);

  DateTime? get inviteLastSharedAt {
    final millis = _prefs.getInt(OnboardingPrefKeys.inviteLastSharedAt);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> recordInviteShared(DateTime at) => _prefs.setInt(
    OnboardingPrefKeys.inviteLastSharedAt,
    at.millisecondsSinceEpoch,
  );

  String? get nicknamePromptedFor =>
      _prefs.getString(OnboardingPrefKeys.nicknamePromptedFor);
  Future<void> markNicknamePrompted(String partnerUid) =>
      _prefs.setString(OnboardingPrefKeys.nicknamePromptedFor, partnerUid);

  bool get invitePromptedAfterPlan =>
      _prefs.getBool(OnboardingPrefKeys.invitePromptedAfterPlan) ?? false;
  Future<void> markInvitePromptedAfterPlan() =>
      _prefs.setBool(OnboardingPrefKeys.invitePromptedAfterPlan, true);

  /// Forgets who the nickname sheet was shown for: after an unlink the
  /// nickname is gone, so re-linking (even with the same person) asks again.
  Future<void> clearNicknamePrompted() =>
      _prefs.remove(OnboardingPrefKeys.nicknamePromptedFor);
}

/// Needs [sharedPreferencesProvider] (overridden in main).
final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  return OnboardingStore(ref.watch(sharedPreferencesProvider));
});
