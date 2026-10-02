import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

import '../../../models/proof_photo.dart';

/// A proof photo after [processProofPhotoBytes]: a fresh JPEG without any
/// metadata, plus the original capture time read before stripping.
class ProcessedProofPhoto {
  const ProcessedProofPhoto({
    required this.jpegBytes,
    required this.width,
    required this.height,
    this.originalTakenAt,
  });

  final Uint8List jpegBytes;
  final int width;
  final int height;

  /// EXIF DateTimeOriginal (or DateTimeDigitized / DateTime) of the input,
  /// interpreted as local time; null when the input had none.
  final DateTime? originalTakenAt;
}

/// Decodes [input] (JPEG, PNG, …), applies its EXIF orientation, shrinks it so
/// the longest side is at most [maxDimension], and re-encodes it as a JPEG with
/// no EXIF at all — no GPS position, camera model or timestamps leave the
/// phone. Returns null when [input] can't be decoded (e.g. HEIC).
///
/// Pure and synchronous so it can run in another isolate; see
/// [processProofPhotoInBackground].
ProcessedProofPhoto? processProofPhotoBytes(
  Uint8List input, {
  int maxDimension = kProofMaxDimension,
  int quality = kProofJpegQuality,
}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  final takenAt = readExifTakenAt(decoded.exif);

  // Rotate the pixels the way the EXIF orientation says, since the tag that
  // told viewers to do so is about to be dropped.
  var image = img.bakeOrientation(decoded);

  final longest = math.max(image.width, image.height);
  if (longest > maxDimension) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: maxDimension,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: maxDimension,
            interpolation: img.Interpolation.average,
          );
  }

  // Drop every EXIF directory (IFD0, EXIF, GPS, interop, thumbnail). The
  // encoder writes no APP1 segment for empty EXIF data.
  image.exif = img.ExifData();

  final jpeg = img.encodeJpg(image, quality: quality);
  return ProcessedProofPhoto(
    jpegBytes: jpeg,
    width: image.width,
    height: image.height,
    originalTakenAt: takenAt,
  );
}

/// Runs [processProofPhotoBytes] off the UI isolate.
Future<ProcessedProofPhoto?> processProofPhotoInBackground(Uint8List input) {
  return compute(_processEntry, input);
}

ProcessedProofPhoto? _processEntry(Uint8List input) =>
    processProofPhotoBytes(input);

/// Re-encodes any picked image (a profile photo) the way proof photos are:
/// decoded, orientation baked in, scaled to [maxDimension] and written as a
/// fresh JPEG — so EXIF (GPS, device model, …) never leaves the phone. Null
/// when the bytes can't be decoded: callers then upload nothing.
Future<Uint8List?> sanitizeImageBytesInBackground(
  Uint8List input, {
  int maxDimension = 1024,
}) {
  return compute(_sanitizeEntry, (input, maxDimension));
}

Uint8List? _sanitizeEntry((Uint8List, int) args) =>
    processProofPhotoBytes(args.$1, maxDimension: args.$2)?.jpegBytes;

const int _tagDateTimeOriginal = 0x9003;
const int _tagDateTimeDigitized = 0x9004;
const int _tagDateTime = 0x0132;

/// The capture time stored in [exif], or null.
DateTime? readExifTakenAt(img.ExifData exif) {
  if (exif.isEmpty) return null;
  final candidates = [
    exif.exifIfd[_tagDateTimeOriginal],
    exif.exifIfd[_tagDateTimeDigitized],
    exif.imageIfd[_tagDateTime],
  ];
  for (final value in candidates) {
    final parsed = parseExifDateTime(value?.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

/// Parses an EXIF date like `2026:09:28 07:15:42` as local time.
///
/// Returns null for empty, zeroed (`0000:00:00 00:00:00`) or malformed values.
DateTime? parseExifDateTime(String? raw) {
  if (raw == null) return null;
  final match = RegExp(
    r'^\s*(\d{4})[:\-](\d{2})[:\-](\d{2})[ T](\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(raw);
  if (match == null) return null;
  final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
  final [year, month, day, hour, minute, second] = parts;
  if (year < 1970 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  if (hour > 23 || minute > 59 || second > 59) return null;
  return DateTime(year, month, day, hour, minute, second);
}
