import '../../../models/proof_photo.dart';
import '../../../utils/analytics.dart';

/// `proof_uploaded {has_photo, source}` — sent for every 했어 report.
///
/// `source` is the photo the user tried to attach (`camera`/`gallery`) or
/// `none`; `has_photo` is whether it actually made it, so
/// `has_photo=0, source=camera` counts failed uploads.
Map<String, Object?> proofUploadedParams(ProofCompletionResult result) => {
  'has_photo': result.hasPhoto,
  'source': result.attemptedSource?.id ?? 'none',
};

void logProofUploaded(ProofCompletionResult result) {
  AnalyticsService.log(
    AnalyticsEvent.proofUploaded,
    proofUploadedParams(result),
  );
}

/// How long the partner took to react, as a coarse bucket (exact gaps would
/// be needlessly precise behavioural data).
String reactionLatencyBucket(Duration? latency) {
  if (latency == null || latency.isNegative) return 'unknown';
  if (latency < const Duration(minutes: 5)) return 'lt_5m';
  if (latency < const Duration(minutes: 30)) return '5m_30m';
  if (latency < const Duration(hours: 2)) return '30m_2h';
  if (latency < const Duration(hours: 6)) return '2h_6h';
  if (latency < const Duration(hours: 24)) return '6h_24h';
  return 'gt_24h';
}

/// `partner_reacted {latency_bucket, surface, reaction, has_photo}` — the
/// partner's one-tap 인정. [reportedAt] is when the record was made.
Map<String, Object?> partnerReactedParams({
  required DateTime? reportedAt,
  required String surface,
  required String reaction,
  required bool hasPhoto,
  DateTime? now,
}) {
  final latency = reportedAt == null
      ? null
      : (now ?? DateTime.now()).difference(reportedAt);
  return {
    'latency_bucket': reactionLatencyBucket(latency),
    'surface': surface,
    'reaction': reaction,
    'has_photo': hasPhoto,
  };
}

void logPartnerReacted({
  required DateTime? reportedAt,
  required String surface,
  required String reaction,
  required bool hasPhoto,
}) {
  AnalyticsService.log(
    AnalyticsEvent.partnerReacted,
    partnerReactedParams(
      reportedAt: reportedAt,
      surface: surface,
      reaction: reaction,
      hasPhoto: hasPhoto,
    ),
  );
}
