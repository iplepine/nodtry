import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/repository_provider.dart';
import '../../../routes/app_router.dart';
import '../../connect/application/invite_services.dart';
import '../../connect/domain/invite_code.dart';
import '../domain/onboarding_gate.dart';

/// The one clipboard look after a new user's first login (spec §4.1): if the
/// invite message — or just the code — was copied, open code entry with the
/// owner already looked up so "{이름}의 운동 약속을 봐줄래요?" shows at once.
///
/// Runs at most once per device ([OnboardingStore.clipboardChecked]), only
/// for new users without a partner, and reads the clipboard only when it
/// holds text, so the iOS paste prompt never appears for nothing. A code
/// nobody holds is ignored silently.
Future<bool> runPostLoginClipboardCheck(
  BuildContext context,
  WidgetRef ref,
) async {
  final OnboardingStore store;
  try {
    store = ref.read(onboardingStoreProvider);
  } catch (_) {
    return false;
  }
  final profile = ref.read(myProfileProvider).value;
  if (profile == null) return false;

  bool? hasPartner;
  try {
    hasPartner = (await ref.read(connectedProfilesProvider.future)).isNotEmpty;
  } catch (_) {
    hasPartner = null;
  }
  final run = shouldRunPostLoginClipboardCheck(
    legacyUser: store.legacyUser(accountCreatedAt: profile.createdAt),
    alreadyChecked: store.clipboardChecked,
    hasPartner: hasPartner,
  );
  if (!run) return false;
  await store.markClipboardChecked();

  final candidate = await ref
      .read(inviteCodeDetectorProvider)
      .fromClipboard(myCode: profile.inviteCode, myUid: profile.uid);
  if (candidate == null || !context.mounted) return false;
  context.push(
    AppRoutes.connectEntry(
      code: candidate.code,
      source: InviteCodeSource.clipboard,
    ),
    extra: candidate.owner,
  );
  return true;
}
