import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/proof_photo.dart';
import '../../../providers/repository_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/terms_notice.dart';
import '../../../utils/error_reporter.dart';
import '../domain/proof_labels.dart';
import '../domain/proof_photo_processing.dart';

/// SharedPreferences flag: the one-time proof photo consent sheet was
/// accepted on this device.
const String kProofConsentAcceptedKey = 'proof.consent_accepted_v1';

/// Whether the consent sheet was accepted ([kProofConsentAcceptedKey]).
class ProofConsentStore {
  ProofConsentStore(this._prefs);

  final SharedPreferences _prefs;

  bool get accepted => _prefs.getBool(kProofConsentAcceptedKey) ?? false;

  Future<void> accept() => _prefs.setBool(kProofConsentAcceptedKey, true);
}

/// Picks a raw image for [source]. Overridable in tests.
typedef ProofImagePicker = Future<Uint8List?> Function(ProofSource source);

/// Strips metadata and resizes a picked image. Overridable in tests.
typedef ProofPhotoProcessor =
    Future<ProcessedProofPhoto?> Function(Uint8List input);

final proofImagePickerProvider = Provider<ProofImagePicker>(
  (ref) => pickProofImageWithImagePicker,
);

final proofPhotoProcessorProvider = Provider<ProofPhotoProcessor>(
  (ref) => processProofPhotoInBackground,
);

/// image_picker, already sized down to [kProofMaxDimension] on the device.
/// The bytes still go through [processProofPhotoBytes], which is what removes
/// the metadata (image_picker keeps EXIF, GPS included, when it resizes).
Future<Uint8List?> pickProofImageWithImagePicker(ProofSource source) async {
  final file = await ImagePicker().pickImage(
    source: source == ProofSource.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    maxWidth: kProofMaxDimension.toDouble(),
    maxHeight: kProofMaxDimension.toDouble(),
    imageQuality: kProofJpegQuality,
    preferredCameraDevice: CameraDevice.rear,
  );
  if (file == null) return null;
  return file.readAsBytes();
}

Future<SharedPreferences> _prefs(WidgetRef ref) async {
  try {
    return ref.read(sharedPreferencesProvider);
  } catch (_) {
    // Not overridden (some tests): fall back to the plugin instance.
    return SharedPreferences.getInstance();
  }
}

/// The whole capture step: one-time consent → 📸 camera / 🖼️ album → pick →
/// strip metadata. Returns null when the user backs out; failures show a
/// snackbar and also return null.
Future<ProofPhotoUpload?> captureProofPhoto(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  final consent = ProofConsentStore(await _prefs(ref));
  if (!consent.accepted) {
    if (!context.mounted) return null;
    final agreed = await showProofConsentSheet(context);
    if (agreed != true) return null;
    await consent.accept();
  }

  if (!context.mounted) return null;
  final source = await showProofSourceSheet(context);
  if (source == null || !context.mounted) return null;

  final Uint8List? raw;
  try {
    raw = await ref.read(proofImagePickerProvider)(source);
  } catch (e, s) {
    // Typically a denied camera/photo permission.
    ErrorReporter.record(e, s, reason: 'proofPick');
    messenger.showSnackBar(SnackBar(content: Text(l10n.proofPickFailed)));
    return null;
  }
  if (raw == null) return null;
  final picked = raw;

  ProcessedProofPhoto? processed;
  if (context.mounted) {
    processed = await _withProgress(
      context,
      () => ref.read(proofPhotoProcessorProvider)(picked),
    );
  }
  if (processed == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.proofPhotoPrepareFailed)),
    );
    return null;
  }

  return ProofPhotoUpload(
    bytes: processed.jpegBytes,
    source: source,
    // Camera: now. Album: the original capture time from EXIF, read before
    // the metadata was stripped (null when the photo had none).
    takenAt: source == ProofSource.camera
        ? DateTime.now()
        : processed.originalTakenAt,
  );
}

/// Runs [task] behind a small blocking spinner (decoding takes a moment).
Future<T?> _withProgress<T>(
  BuildContext context,
  Future<T?> Function() task,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var shown = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    ),
  ).whenComplete(() => shown = false);
  try {
    return await task();
  } catch (e, s) {
    ErrorReporter.record(e, s, reason: 'proofProcess');
    return null;
  } finally {
    if (shown && navigator.mounted) navigator.pop();
  }
}

/// One-time sheet before the first proof photo. True when accepted.
Future<bool?> showProofConsentSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const ProofConsentSheet(),
  );
}

class ProofConsentSheet extends StatelessWidget {
  const ProofConsentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = <(IconData, String)>[
      (Icons.favorite_outline_rounded, l10n.proofConsentOnlyPartner),
      (Icons.location_off_outlined, l10n.proofConsentLocationRemoved),
      (Icons.link_off_rounded, l10n.proofConsentAfterDisconnect),
      (Icons.block_rounded, l10n.proofConsentNoInappropriate),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.proofConsentTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            for (final (icon, text) in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TermsNotice(text: l10n.termsNoticePhoto),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const ValueKey('proof-consent-agree'),
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.proofConsentAgree,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📸 camera (first, the default) or 🖼️ album.
Future<ProofSource?> showProofSourceSheet(BuildContext context) {
  return showModalBottomSheet<ProofSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Text(
                  l10n.proofSourceSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _SourceTile(
                key: const ValueKey('proof-source-camera'),
                title: l10n.proofSourceCamera,
                subtitle: l10n.proofSourceCameraHint,
                highlighted: true,
                onTap: () => Navigator.pop(context, ProofSource.camera),
              ),
              const SizedBox(height: 8),
              _SourceTile(
                key: const ValueKey('proof-source-gallery'),
                title: l10n.proofSourceGallery,
                subtitle: l10n.proofSourceGalleryHint,
                onTap: () => Navigator.pop(context, ProofSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.primarySoft : AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the processed photo with an optional 한마디 before sending.
/// Returns the note ('' for none), or null when the user cancels.
Future<String?> showProofPreviewSheet(
  BuildContext context, {
  required ProofPhotoUpload upload,
  String? title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ProofPreviewSheet(upload: upload, title: title),
  );
}

class ProofPreviewSheet extends StatefulWidget {
  const ProofPreviewSheet({super.key, required this.upload, this.title});

  final ProofPhotoUpload upload;
  final String? title;

  @override
  State<ProofPreviewSheet> createState() => _ProofPreviewSheetState();
}

class _ProofPreviewSheetState extends State<ProofPreviewSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badge = proofSourceBadgeLabel(
      l10n,
      source: widget.upload.source,
      takenAt: widget.upload.takenAt,
    );
    final maxPhotoHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.proofPreviewTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.title != null && widget.title!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.title!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPhotoHeight),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.memory(
                      widget.upload.bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      gaplessPlayback: true,
                    ),
                    if (badge != null)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: ProofBadgeChip(label: badge),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('proof-preview-note'),
              controller: _controller,
              maxLength: 300,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: l10n.actionNoteHintDefault,
                hintStyle: TextStyle(color: AppColors.textDisabled),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    key: const ValueKey('proof-preview-submit'),
                    onPressed: () =>
                        Navigator.pop(context, _controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.proofPreviewSubmit,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The small dark pill with the provenance label (📸 방금 찍음 · 19:42).
class ProofBadgeChip extends StatelessWidget {
  const ProofBadgeChip({super.key, required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
