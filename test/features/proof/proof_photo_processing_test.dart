import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nod_try/features/proof/domain/proof_photo_processing.dart';

/// A JPEG carrying the metadata a phone writes: camera make/model, capture
/// time, and a GPS position.
Uint8List _jpegWithExif({
  int width = 64,
  int height = 48,
  int? orientation,
  String dateTimeOriginal = '2026:09:28 07:15:42',
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(200, 40, 80));
  image.exif.imageIfd['Make'] = img.IfdValueAscii('TestPhoneMaker');
  image.exif.imageIfd['Model'] = img.IfdValueAscii('SecretModel X');
  if (orientation != null) image.exif.imageIfd.orientation = orientation;
  image.exif.exifIfd['DateTimeOriginal'] = img.IfdValueAscii(dateTimeOriginal);
  image.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');
  image.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(3755, 100);
  image.exif.gpsIfd['GPSLongitudeRef'] = img.IfdValueAscii('E');
  image.exif.gpsIfd['GPSLongitude'] = img.IfdValueRational(12697, 100);
  return img.encodeJpg(image);
}

bool _containsAscii(Uint8List bytes, String text) {
  final needle = ascii.encode(text);
  outer:
  for (var i = 0; i + needle.length <= bytes.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}

void main() {
  group('processProofPhotoBytes', () {
    test('the fixture really carries EXIF and GPS (sanity check)', () {
      final input = _jpegWithExif();
      final exif = img.decodeJpgExif(input);
      expect(exif, isNotNull);
      expect(exif!.gpsIfd.isEmpty, isFalse);
      expect(_containsAscii(input, 'Exif'), isTrue);
      expect(_containsAscii(input, 'SecretModel X'), isTrue);
    });

    test('strips every EXIF tag, GPS included', () {
      final input = _jpegWithExif();

      final output = processProofPhotoBytes(input)!;

      final exif = img.decodeJpgExif(output.jpegBytes);
      expect(exif == null || exif.isEmpty, isTrue);
      // No APP1 "Exif" segment and none of the identifying strings survive.
      expect(_containsAscii(output.jpegBytes, 'Exif'), isFalse);
      expect(_containsAscii(output.jpegBytes, 'SecretModel X'), isFalse);
      expect(_containsAscii(output.jpegBytes, 'TestPhoneMaker'), isFalse);
      expect(_containsAscii(output.jpegBytes, '2026:09:28'), isFalse);
      // Still a valid JPEG of the same picture.
      final decoded = img.decodeJpg(output.jpegBytes)!;
      expect(decoded.width, 64);
      expect(decoded.height, 48);
    });

    test('reads the original capture time before stripping it', () {
      final output = processProofPhotoBytes(_jpegWithExif())!;
      expect(output.originalTakenAt, DateTime(2026, 9, 28, 7, 15, 42));
    });

    test('a photo without EXIF has no capture time', () {
      final plain = img.encodeJpg(img.Image(width: 10, height: 10));
      final output = processProofPhotoBytes(plain)!;
      expect(output.originalTakenAt, isNull);
    });

    test('bakes the EXIF orientation into the pixels', () {
      // Orientation 6 = rotate 90° clockwise to display.
      final input = _jpegWithExif(width: 64, height: 32, orientation: 6);

      final output = processProofPhotoBytes(input)!;

      expect(output.width, 32);
      expect(output.height, 64);
      final decoded = img.decodeJpg(output.jpegBytes)!;
      expect(decoded.width, 32);
      expect(decoded.height, 64);
    });

    test('shrinks the longest side to 1440 px', () {
      final wide = img.encodeJpg(img.Image(width: 3000, height: 1000));
      final tall = img.encodeJpg(img.Image(width: 900, height: 2000));

      final w = processProofPhotoBytes(wide)!;
      final t = processProofPhotoBytes(tall)!;

      expect((w.width, w.height), (1440, 480));
      expect(t.height, 1440);
      expect(t.width, 648);
    });

    test('re-encodes a PNG as JPEG', () {
      final png = img.encodePng(img.Image(width: 20, height: 10));
      final output = processProofPhotoBytes(png)!;
      expect(img.decodeJpg(output.jpegBytes), isNotNull);
    });

    test('returns null for bytes it cannot decode', () {
      expect(
        processProofPhotoBytes(Uint8List.fromList(utf8.encode('not a photo'))),
        isNull,
      );
    });
  });

  group('parseExifDateTime', () {
    test('parses the EXIF format as local time', () {
      expect(
        parseExifDateTime('2026:09:28 19:42:05'),
        DateTime(2026, 9, 28, 19, 42, 5),
      );
    });

    test('rejects empty, zeroed and malformed values', () {
      expect(parseExifDateTime(null), isNull);
      expect(parseExifDateTime(''), isNull);
      expect(parseExifDateTime('0000:00:00 00:00:00'), isNull);
      expect(parseExifDateTime('2026:13:01 10:00:00'), isNull);
      expect(parseExifDateTime('yesterday'), isNull);
    });
  });
}
