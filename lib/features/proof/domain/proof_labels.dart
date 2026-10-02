import '../../../l10n/app_localizations.dart';
import '../../../models/proof_photo.dart';
import '../../../utils/time_formatter.dart';

/// Support inbox (also on support/index.html and the privacy policy).
const String kSupportEmail = 'devhohouse@gmail.com';

/// The provenance badge on a proof photo, so a partner can tell a fresh shot
/// from a recycled album photo:
/// - camera, taken today: `📸 방금 찍음 · 19:42`
/// - camera, earlier day: `📸 카메라 · 9/28 19:42`
/// - album with a known capture date: `🖼️ 앨범 · 9/28 촬영`
/// - album without one: `🖼️ 앨범`
///
/// Null when the source is unknown (nothing to claim).
String? proofSourceBadgeLabel(
  AppLocalizations l10n, {
  required ProofSource? source,
  DateTime? takenAt,
  DateTime? now,
}) {
  switch (source) {
    case null:
      return null;
    case ProofSource.camera:
      if (takenAt == null) return l10n.proofBadgeCameraJustNow;
      final today = now ?? DateTime.now();
      final time = TimeFormatter.formatExactTime(takenAt);
      if (_sameDay(takenAt, today)) return l10n.proofBadgeCamera(time);
      return l10n.proofBadgeCameraOn('${_monthDay(takenAt)} $time');
    case ProofSource.gallery:
      if (takenAt == null) return l10n.proofBadgeGallery;
      return l10n.proofBadgeGalleryTaken(_monthDay(takenAt));
  }
}

String _monthDay(DateTime date) => '${date.month}/${date.day}';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A `mailto:` draft to the support inbox for reporting one proof photo.
///
/// Only the action id goes into the draft — enough to find the record, with
/// nothing personal in it.
Uri proofReportMailUri({
  required String actionId,
  required String subject,
  required String body,
}) {
  // Uri(queryParameters:) encodes spaces as '+', which mail apps show
  // literally; percent-encode each part instead.
  final query =
      'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
  return Uri.parse('mailto:$kSupportEmail?$query');
}
