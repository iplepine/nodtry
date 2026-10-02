import 'dart:typed_data';

import 'plan_model.dart';

/// Where a proof photo (인증샷) came from. Stored as `actions.proofSource`.
enum ProofSource {
  camera('camera'),
  gallery('gallery');

  const ProofSource(this.id);

  /// Stored value (pivot spec §9): `camera` or `gallery`.
  final String id;

  /// Parses a stored value; null for a missing or unknown one.
  static ProofSource? fromId(Object? id) {
    for (final source in values) {
      if (source.id == id) return source;
    }
    return null;
  }
}

/// The four one-tap 인정 reactions, in display order. All of them are already
/// in `ReactionIcon`, so app versions from before the pivot render them too.
const List<String> kProofReactions = ['❤️', '🔥', '💪', '👏'];

/// How long an upload may take before the record is saved without the photo.
const Duration kProofUploadTimeout = Duration(seconds: 8);

/// Longest side of an uploaded proof photo, in pixels.
const int kProofMaxDimension = 1440;

/// JPEG quality of an uploaded proof photo.
const int kProofJpegQuality = 85;

/// Storage rules reject proof photos of 3 MB or more; a download never needs
/// more than this.
const int kProofMaxBytes = 3 * 1024 * 1024;

/// A proof photo ready to upload: re-encoded JPEG bytes without metadata.
class ProofPhotoUpload {
  const ProofPhotoUpload({
    required this.bytes,
    required this.source,
    this.takenAt,
  });

  /// JPEG bytes with every EXIF/GPS tag stripped.
  final Uint8List bytes;

  final ProofSource source;

  /// Camera: the capture time. Gallery: the original EXIF capture time when
  /// the photo carried one (read before the metadata was stripped), else null.
  final DateTime? takenAt;
}

/// What happened to a 했어 report.
class ProofCompletionResult {
  const ProofCompletionResult({
    this.actionId,
    this.photoPath,
    this.attemptedSource,
    this.queued = false,
  });

  /// The new `actions` document id, or null when nothing was written (signed
  /// out).
  final String? actionId;

  /// Storage path of the uploaded proof photo; null without a photo.
  final String? photoPath;

  /// The source of the photo the user tried to attach, if any.
  final ProofSource? attemptedSource;

  /// The record was saved on this device but the server hasn't confirmed it
  /// yet (offline): it syncs — and reaches the partner — once back online.
  final bool queued;

  bool get hasPhoto => photoPath != null;

  /// A photo was picked but could not be uploaded (failure or timeout); the
  /// record itself was still saved.
  bool get photoFailed => attemptedSource != null && photoPath == null;
}

/// Storage path of a proof photo: `proofs/{ownerUid}/{planId}/{actionId}.jpg`.
///
/// Firestore stores this path, never a download URL: plans and actions are
/// readable by every signed-in user, while the Storage rules only let the
/// owner and the plan's partner read the object behind the path.
String proofPhotoPathFor({
  required String ownerUid,
  required String planId,
  required String actionId,
}) {
  return 'proofs/$ownerUid/$planId/$actionId.jpg';
}

/// The parts of a proof photo path, or null if [path] is not one.
({String ownerUid, String planId, String actionId})? parseProofPhotoPath(
  String? path,
) {
  if (path == null) return null;
  final match = RegExp(
    r'^proofs/([^/]+)/([^/]+)/([^/]+)\.jpg$',
  ).firstMatch(path);
  if (match == null) return null;
  return (
    ownerUid: match.group(1)!,
    planId: match.group(2)!,
    actionId: match.group(3)!,
  );
}

/// The plan's proof photo for *today's* report, or null.
///
/// `plans.lastProofPhotoPath` keeps pointing at the last photo even when a
/// later report has none, so the photo counts only when it was taken today and
/// belongs to the latest `done` action (`lastActionId`).
String? todayProofPhotoPathOf(Plan? plan, {DateTime? now}) {
  if (plan == null) return null;
  final path = plan.lastProofPhotoPath;
  final at = plan.lastProofAt;
  if (path == null || path.isEmpty || at == null) return null;
  final today = now ?? DateTime.now();
  if (at.year != today.year || at.month != today.month || at.day != today.day) {
    return null;
  }
  final lastActionId = plan.lastActionId;
  if (lastActionId != null &&
      parseProofPhotoPath(path)?.actionId != lastActionId) {
    return null;
  }
  return path;
}
