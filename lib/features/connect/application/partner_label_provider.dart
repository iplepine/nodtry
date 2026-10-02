import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_provider.dart';
import '../domain/partner_label.dart';

export '../domain/partner_label.dart';

/// The one place the partner's on-screen name comes from.
///
/// `ref.watch(partnerLabelProvider).resolve(l10n)` is nickname ?? partner
/// display name ?? 짝꿍 (spec §3). View models without a BuildContext use
/// [PartnerLabel.preferred] (or [PartnerLabel.preferredFor] for a specific
/// uid) and leave the localized fallback to the widget.
///
/// The nickname only applies while a partner is connected.
final partnerLabelProvider = Provider<PartnerLabel>((ref) {
  final partner = ref.watch(connectedProfilesProvider).value?.firstOrNull?.user;
  if (partner == null) return PartnerLabel.none;
  final nickname = ref.watch(
    myProfileProvider.select((profile) => profile.value?.partnerNickname),
  );
  return PartnerLabel(
    partnerUid: partner.uid,
    nickname: nickname,
    displayName: partner.displayName,
  );
});
