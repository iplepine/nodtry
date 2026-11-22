import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/plan_model.dart';
import '../../connect/application/partner_label_provider.dart';
import '../domain/duo_recap.dart';
import 'duo_stats_provider.dart';

export '../domain/duo_recap.dart';

/// The monthly recap of the month starting on the given day (see
/// [recapMonthOf]), for me and my partner — or for me alone without one.
/// Null until the plans it needs are loaded.
final duoRecapProvider = Provider.autoDispose.family<DuoRecap?, DateTime>((
  ref,
  month,
) {
  final myPlans = ref.watch(myDuoPlansProvider);
  if (myPlans == null) return null;

  final partnerUid = ref.watch(
    partnerLabelProvider.select((label) => label.partnerUid),
  );
  var partnerPlans = const <Plan>[];
  if (partnerUid != null) {
    final theirs = ref.watch(duoPlansProvider(partnerUid)).value;
    if (theirs == null) return null;
    partnerPlans = theirs;
  }

  return computeDuoRecap(
    myPlans: myPlans,
    partnerPlans: partnerPlans,
    month: month,
    today: ref.watch(duoTodayProvider),
    hasPartner: partnerUid != null,
    linkedSince: partnerUid == null
        ? null
        : ref.watch(partnerLinkedSinceProvider),
  );
});

/// The months the recap sheet can show, newest first; null while my plans
/// load.
final duoRecapMonthsProvider = Provider.autoDispose<List<DateTime>?>((ref) {
  final myPlans = ref.watch(myDuoPlansProvider);
  if (myPlans == null) return null;
  return recapMonthsOf(myPlans, today: ref.watch(duoTodayProvider));
});
