import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/features/proof/domain/proof_labels.dart';
import 'package:nod_try/features/proof/domain/proof_photo_processing.dart';
import 'package:nod_try/features/proof/presentation/proof_capture.dart';
import 'package:nod_try/features/proof/presentation/proof_photo_view.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/proof_photo.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _jpegTakenOn(String exifDate) {
  final image = img.Image(width: 30, height: 20);
  image.exif.exifIfd['DateTimeOriginal'] = img.IfdValueAscii(exifDate);
  image.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');
  return img.encodeJpg(image);
}

class _FakeRecordRepository extends Fake implements RecordRepository {
  final deleted = <String>[];

  @override
  Future<void> deleteProofPhoto(String photoPath) async {
    deleted.add(photoPath);
  }
}

void main() {
  late SharedPreferences prefs;
  late List<ProofSource> picked;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    picked = [];
  });

  Widget harness({
    required void Function(ProofPhotoUpload?) onResult,
    Uint8List? pickedBytes,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        proofImagePickerProvider.overrideWithValue((source) async {
          picked.add(source);
          return pickedBytes ?? _jpegTakenOn('2026:09:28 07:15:00');
        }),
        // Synchronous here; the app runs the same function in an isolate.
        proofPhotoProcessorProvider.overrideWithValue(
          (bytes) async => processProofPhotoBytes(bytes),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async =>
                  onResult(await captureProofPhoto(context, ref)),
              child: const Text('capture'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('first proof shows the consent sheet once, then the picker', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final results = <ProofPhotoUpload?>[];
    await tester.pumpWidget(harness(onResult: results.add));

    await tester.tap(find.text('capture'));
    await tester.pumpAndSettle();

    // The spec's four promises.
    expect(find.text(l10n.proofConsentTitle), findsOneWidget);
    expect(find.text(l10n.proofConsentOnlyPartner), findsOneWidget);
    expect(find.text(l10n.proofConsentLocationRemoved), findsOneWidget);
    expect(find.text(l10n.proofConsentAfterDisconnect), findsOneWidget);
    expect(find.text(l10n.proofConsentNoInappropriate), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('proof-consent-agree')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(kProofConsentAcceptedKey), isTrue);

    // Camera first, album second.
    expect(find.text(l10n.proofSourceCamera), findsOneWidget);
    expect(find.text(l10n.proofSourceGallery), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('proof-source-gallery')));
    await tester.pumpAndSettle();

    expect(picked, [ProofSource.gallery]);
    final upload = results.single!;
    expect(upload.source, ProofSource.gallery);
    // Album: the EXIF capture date, read before the metadata was stripped.
    expect(upload.takenAt, DateTime(2026, 9, 28, 7, 15));
    final exif = img.decodeJpgExif(upload.bytes);
    expect(exif == null || exif.isEmpty, isTrue);

    // Second time: straight to the picker.
    await tester.tap(find.text('capture'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.proofConsentTitle), findsNothing);
    await tester.tap(find.byKey(const ValueKey('proof-source-camera')));
    await tester.pumpAndSettle();

    final camera = results.last!;
    expect(camera.source, ProofSource.camera);
    // Camera: the capture time is now, whatever the file says.
    expect(
      DateTime.now().difference(camera.takenAt!).inMinutes.abs(),
      lessThan(2),
    );
  });

  testWidgets('declining the consent sheet takes no photo', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final results = <ProofPhotoUpload?>[];
    await tester.pumpWidget(harness(onResult: results.add));

    await tester.tap(find.text('capture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(picked, isEmpty);
    expect(prefs.getBool(kProofConsentAcceptedKey), isNull);
  });

  testWidgets('an undecodable photo is refused with a message', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await prefs.setBool(kProofConsentAcceptedKey, true);
    final results = <ProofPhotoUpload?>[];
    await tester.pumpWidget(
      harness(
        onResult: results.add,
        pickedBytes: Uint8List.fromList(const [0, 1, 2, 3]),
      ),
    );

    await tester.tap(find.text('capture'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('proof-source-camera')));
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(find.text(l10n.proofPhotoPrepareFailed), findsOneWidget);
  });

  group('viewer menu', () {
    final bytes = img.encodeJpg(img.Image(width: 4, height: 4));
    const path = 'proofs/partner-uid/plan-1/action-7.jpg';

    Widget viewer({
      required bool isOwner,
      required _FakeRecordRepository repository,
      List<Uri>? mails,
    }) {
      final now = DateTime.now();
      return ProviderScope(
        overrides: [
          recordRepositoryProvider.overrideWithValue(repository),
          proofPhotoCacheProvider.overrideWith(
            (ref) => ProofPhotoCache(
              fetch: (_) async => bytes,
              directory: () async => null,
            ),
          ),
          proofMailLauncherProvider.overrideWithValue((uri) async {
            mails?.add(uri);
            return true;
          }),
          connectedProfilesProvider.overrideWith(
            (ref) async => [
              ConnectedUser(
                user: UserModel(
                  uid: 'partner-uid',
                  displayName: '지민',
                  createdAt: now,
                  updatedAt: now,
                ),
                isSupported: true,
                isCheering: true,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProofPhoto(path: path, isOwner: isOwner, height: 120),
          ),
        ),
      );
    }

    testWidgets('the partner can report (mail draft) or disconnect', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      final mails = <Uri>[];
      await tester.pumpWidget(
        viewer(
          isOwner: false,
          repository: _FakeRecordRepository(),
          mails: mails,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProofPhoto));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('proof-viewer-menu')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.proofViewerReport), findsOneWidget);
      expect(find.text(l10n.usDisconnectTooltip), findsOneWidget);
      expect(find.text(l10n.proofViewerDelete), findsNothing);

      await tester.tap(find.text(l10n.proofViewerReport));
      await tester.pumpAndSettle();
      expect(mails.single.path, kSupportEmail);
      expect(Uri.decodeComponent(mails.single.query), contains('action-7'));

      await tester.tap(find.byKey(const ValueKey('proof-viewer-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.usDisconnectTooltip));
      await tester.pumpAndSettle();
      // The existing 연결 끊기 confirmation.
      expect(find.text(l10n.usDisconnectDialogContent('지민')), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
    });

    testWidgets('the owner can delete the photo', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
      final repository = _FakeRecordRepository();
      await tester.pumpWidget(viewer(isOwner: true, repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProofPhoto));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('proof-viewer-menu')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.proofViewerReport), findsNothing);

      await tester.tap(find.text(l10n.proofViewerDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('proof-delete-confirm')));
      await tester.pumpAndSettle();

      expect(repository.deleted, [path]);
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.text(l10n.proofDeleted), findsOneWidget);
    });
  });
}
