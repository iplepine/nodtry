import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/onboarding/domain/onboarding_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('device cohort', () {
    test('a device an older build ran on is legacy', () {
      expect(
        resolveDeviceCohort(hadTutorialFlag: true, hadCachedProfile: false),
        DeviceCohort.legacy,
      );
      // Signed-in users skipped the tutorial, but left a cached profile.
      expect(
        resolveDeviceCohort(hadTutorialFlag: false, hadCachedProfile: true),
        DeviceCohort.legacy,
      );
    });

    test('a clean device is a new install', () {
      expect(
        resolveDeviceCohort(hadTutorialFlag: false, hadCachedProfile: false),
        DeviceCohort.fresh,
      );
    });

    test('a recorded cohort wins over the flags', () {
      expect(
        resolveDeviceCohort(
          stored: 'new',
          hadTutorialFlag: true,
          hadCachedProfile: true,
        ),
        DeviceCohort.fresh,
      );
      expect(
        resolveDeviceCohort(
          stored: 'legacy',
          hadTutorialFlag: false,
          hadCachedProfile: false,
        ),
        DeviceCohort.legacy,
      );
    });

    test(
      'recorded once at start, before this build writes the tutorial flag',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        expect(recordDeviceCohort(prefs), DeviceCohort.fresh);
        expect(prefs.getString(OnboardingPrefKeys.deviceCohort), 'new');

        // The new tutorial then sets its flag; the device stays "new".
        await prefs.setBool(kLegacyTutorialKey, true);
        expect(recordDeviceCohort(prefs), DeviceCohort.fresh);
        expect(OnboardingStore(prefs).deviceCohort, DeviceCohort.fresh);
      },
    );

    test('an upgraded device is recorded as legacy', () async {
      SharedPreferences.setMockInitialValues({kLegacyTutorialKey: true});
      final prefs = await SharedPreferences.getInstance();
      expect(recordDeviceCohort(prefs), DeviceCohort.legacy);
      expect(prefs.getString(OnboardingPrefKeys.deviceCohort), 'legacy');
    });
  });

  group('isLegacyUser', () {
    test('legacy device, or an account from before the pivot', () {
      expect(isLegacyUser(cohort: DeviceCohort.legacy), isTrue);
      expect(
        isLegacyUser(
          cohort: DeviceCohort.fresh,
          accountCreatedAt: DateTime(2026, 9, 1),
        ),
        isTrue,
      );
      expect(
        isLegacyUser(
          cohort: DeviceCohort.fresh,
          accountCreatedAt: DateTime(2026, 10, 2),
        ),
        isFalse,
      );
      expect(isLegacyUser(cohort: DeviceCohort.fresh), isFalse);
    });
  });

  group('rename notice', () {
    test('only existing users, only once', () {
      expect(
        shouldShowPivotNotice(legacyUser: true, seenOnDevice: false),
        isTrue,
      );
      expect(
        shouldShowPivotNotice(legacyUser: false, seenOnDevice: false),
        isFalse,
      );
      expect(
        shouldShowPivotNotice(legacyUser: true, seenOnDevice: true),
        isFalse,
      );
      expect(
        shouldShowPivotNotice(
          legacyUser: true,
          seenOnDevice: false,
          seenOnAccount: true,
        ),
        isFalse,
      );
    });
  });

  group('postLoginRoute', () {
    test('a new user without a partner sees the invite step', () {
      expect(
        postLoginRoute(
          legacyUser: false,
          inviteStepDone: false,
          pendingCodeEntry: false,
          hasPartner: false,
        ),
        PostLoginRoute.inviteStep,
      );
      // Not known yet: the invite step itself leaves if a partner shows up.
      expect(
        postLoginRoute(
          legacyUser: false,
          inviteStepDone: false,
          pendingCodeEntry: false,
        ),
        PostLoginRoute.inviteStep,
      );
    });

    test('"초대 코드 받았어요" goes straight to code entry', () {
      expect(
        postLoginRoute(
          legacyUser: false,
          inviteStepDone: false,
          pendingCodeEntry: true,
          hasPartner: false,
        ),
        PostLoginRoute.codeEntry,
      );
    });

    test('someone with a partner always goes home', () {
      expect(
        postLoginRoute(
          legacyUser: false,
          inviteStepDone: false,
          pendingCodeEntry: true,
          hasPartner: true,
        ),
        PostLoginRoute.home,
      );
    });

    test('dismissed, or an existing user: home', () {
      expect(
        postLoginRoute(
          legacyUser: false,
          inviteStepDone: true,
          pendingCodeEntry: false,
          hasPartner: false,
        ),
        PostLoginRoute.home,
      );
      expect(
        postLoginRoute(
          legacyUser: true,
          inviteStepDone: false,
          pendingCodeEntry: false,
          hasPartner: false,
        ),
        PostLoginRoute.home,
      );
    });
  });

  test('the clipboard is checked once, for new users with no partner', () {
    expect(
      shouldRunPostLoginClipboardCheck(
        legacyUser: false,
        alreadyChecked: false,
        hasPartner: false,
      ),
      isTrue,
    );
    expect(
      shouldRunPostLoginClipboardCheck(
        legacyUser: false,
        alreadyChecked: true,
        hasPartner: false,
      ),
      isFalse,
    );
    expect(
      shouldRunPostLoginClipboardCheck(
        legacyUser: true,
        alreadyChecked: false,
        hasPartner: false,
      ),
      isFalse,
    );
    expect(
      shouldRunPostLoginClipboardCheck(
        legacyUser: false,
        alreadyChecked: false,
        hasPartner: true,
      ),
      isFalse,
    );
    expect(
      shouldRunPostLoginClipboardCheck(
        legacyUser: false,
        alreadyChecked: false,
        hasPartner: null,
      ),
      isFalse,
    );
  });

  test('the nickname sheet is offered once per partner, without one', () {
    expect(
      shouldPromptNickname(partnerUid: 'p', nickname: null, promptedFor: null),
      isTrue,
    );
    expect(
      shouldPromptNickname(partnerUid: 'p', nickname: '자기', promptedFor: null),
      isFalse,
    );
    expect(
      shouldPromptNickname(partnerUid: 'p', nickname: null, promptedFor: 'p'),
      isFalse,
    );
    // A new partner gets asked again.
    expect(
      shouldPromptNickname(partnerUid: 'q', nickname: null, promptedFor: 'p'),
      isTrue,
    );
    expect(
      shouldPromptNickname(partnerUid: null, nickname: null, promptedFor: null),
      isFalse,
    );
  });

  group('OnboardingStore', () {
    test('pending code entry is kept and cleared', () async {
      SharedPreferences.setMockInitialValues({});
      final store = OnboardingStore(await SharedPreferences.getInstance());
      expect(store.pendingCodeEntry, isFalse);

      await store.setPendingCodeEntry(code: 'K7MP2QXR', source: 'link');
      expect(store.pendingCodeEntry, isTrue);
      expect(store.pendingInviteCode, 'K7MP2QXR');
      expect(store.pendingInviteSource, 'link');

      await store.clearPendingCodeEntry();
      expect(store.pendingCodeEntry, isFalse);
      expect(store.pendingInviteCode, isNull);
      expect(store.pendingInviteSource, isNull);
    });

    test('flags persist', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = OnboardingStore(prefs);
      await store.markInviteStepDone();
      await store.markPivotNoticeSeen();
      await store.markClipboardChecked();
      await store.markNicknamePrompted('p');
      await store.recordInviteShared(DateTime(2026, 10, 3, 9));

      final again = OnboardingStore(prefs);
      expect(again.inviteStepDone, isTrue);
      expect(again.pivotNoticeSeen, isTrue);
      expect(again.clipboardChecked, isTrue);
      expect(again.nicknamePromptedFor, 'p');
      expect(again.inviteLastSharedAt, DateTime(2026, 10, 3, 9));
    });

    test('legacyUser combines the device and the account', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingPrefKeys.deviceCohort: 'new',
      });
      final store = OnboardingStore(await SharedPreferences.getInstance());
      expect(
        store.legacyUser(accountCreatedAt: DateTime(2026, 10, 3)),
        isFalse,
      );
      expect(store.legacyUser(accountCreatedAt: DateTime(2025, 1, 1)), isTrue);
    });
  });
}
