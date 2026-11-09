/// "같이 했어": the couple worked out together, so one log (and at most one
/// proof photo) covers both. Data contract (all optional, additive — spec §9;
/// see also functions/src/together.ts):
///
/// - `actions/{id}` (my `done`): [kTogetherWithUidField] +
///   [kTogetherPartnerPlanIdField] — the partner and their plan.
/// - `plans/{id}` (my plan): [kLastTogetherField] — a [TogetherMark], so the
///   partner's app can show "{name}가 같이 했대요" without another query.
/// - `actions/{id}` (the partner's own `done`, written only when they tap
///   나도 했어): [kSharedProofFromUidField] + [kTogetherActionIdField], and
///   my photo's `proofPhotoPath` / `proofSource` / `proofTakenAt` when I
///   attached one. `proofSource` keeps its original value (`camera|gallery`).
library;

import 'package:cloud_firestore/cloud_firestore.dart';

const String kTogetherWithUidField = 'togetherWithUid';
const String kTogetherPartnerPlanIdField = 'togetherPartnerPlanId';
const String kLastTogetherField = 'lastTogether';
const String kSharedProofFromUidField = 'sharedProofFromUid';
const String kTogetherActionIdField = 'togetherActionId';

/// Who and which plan a 했어 report says we did together.
class TogetherTag {
  const TogetherTag({required this.partnerUid, required this.partnerPlanId});

  final String partnerUid;
  final String partnerPlanId;

  Map<String, dynamic> toActionFields() => {
    kTogetherWithUidField: partnerUid,
    kTogetherPartnerPlanIdField: partnerPlanId,
  };
}

/// `plans.lastTogether`: the owner's latest "같이 했어" record.
class TogetherMark {
  const TogetherMark({
    required this.actionId,
    required this.withUid,
    required this.planId,
    required this.at,
  });

  /// The owner's `done` action that says "같이 했어".
  final String actionId;

  /// The partner it names.
  final String withUid;

  /// The partner's plan it is for.
  final String planId;

  /// When it was recorded.
  final DateTime at;

  Map<String, dynamic> toMap() => {
    'actionId': actionId,
    'withUid': withUid,
    'planId': planId,
    'at': Timestamp.fromDate(at),
  };

  /// Null unless every field is there with the right type.
  static TogetherMark? fromMap(Object? value) {
    if (value is! Map) return null;
    String? str(Object? v) => v is String && v.isNotEmpty ? v : null;
    final actionId = str(value['actionId']);
    final withUid = str(value['withUid']);
    final planId = str(value['planId']);
    final at = value['at'];
    if (actionId == null || withUid == null || planId == null) return null;
    if (at is! Timestamp) return null;
    return TogetherMark(
      actionId: actionId,
      withUid: withUid,
      planId: planId,
      at: at.toDate(),
    );
  }
}

/// What came of a 나도 했어 tap.
enum TogetherConfirmOutcome {
  /// My record was saved (with the shared photo when there was one).
  logged,

  /// I had already recorded that plan today; nothing was written.
  alreadyLogged,

  /// The partner's record no longer asks (deleted, another day, not for me
  /// or not for this plan); nothing was written.
  unavailable,
}

class TogetherConfirmResult {
  const TogetherConfirmResult(
    this.outcome, {
    this.actionId,
    this.photoPath,
    this.queued = false,
  });

  final TogetherConfirmOutcome outcome;

  /// My new `actions` id, when [outcome] is [TogetherConfirmOutcome.logged].
  final String? actionId;

  /// The shared photo (under the partner's folder), when there was one.
  final String? photoPath;

  /// Saved here but not confirmed by the server yet (offline).
  final bool queued;

  bool get logged => outcome == TogetherConfirmOutcome.logged;
}
