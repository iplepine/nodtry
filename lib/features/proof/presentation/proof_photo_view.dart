import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/connected_user.dart';
import '../../../models/proof_photo.dart';
import '../../../providers/repository_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/error_reporter.dart';
import '../../us/presentation/widgets/disconnect_partner_dialog.dart';
import '../data/proof_photo_cache.dart';
import '../domain/proof_labels.dart';
import 'proof_capture.dart' show ProofBadgeChip;

/// Opens a `mailto:` draft. Overridable in tests.
typedef ProofMailLauncher = Future<bool> Function(Uri uri);

final proofMailLauncherProvider = Provider<ProofMailLauncher>((ref) {
  return (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[ProofPhoto] mail launch failed: $e');
      return false;
    }
  };
});

/// A proof photo (인증샷) loaded by Storage path through
/// [proofPhotoCacheProvider], with a provenance badge. Tapping it opens
/// [ProofPhotoViewer].
class ProofPhoto extends ConsumerStatefulWidget {
  const ProofPhoto({
    super.key,
    required this.path,
    this.source,
    this.takenAt,
    this.isOwner = false,
    this.height = 220,
    this.width = double.infinity,
    this.borderRadius = 14,
    this.showBadge = true,
    this.resolveMetaFromAction = false,
  });

  /// `proofs/{uid}/{planId}/{actionId}.jpg`.
  final String path;

  /// `camera` / `gallery` (raw stored value); null hides the badge.
  final String? source;
  final DateTime? takenAt;

  /// The viewer offers 사진 삭제 to the owner, 신고하기 / 연결 끊기 to the
  /// partner.
  final bool isOwner;

  final double height;
  final double width;
  final double borderRadius;
  final bool showBadge;

  /// When [source] is unknown (a plan only stores the path), read the badge's
  /// source and capture time from the action the path points at.
  final bool resolveMetaFromAction;

  @override
  ConsumerState<ProofPhoto> createState() => _ProofPhotoState();
}

class _ProofPhotoState extends ConsumerState<ProofPhoto> {
  Uint8List? _bytes;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProofPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  void _load() {
    final cache = ref.read(proofPhotoCacheProvider);
    final cached = cache.peek(widget.path);
    final request = ++_request;
    if (cached != null) {
      _bytes = cached;
      _failed = false;
      return;
    }
    _bytes = null;
    _failed = false;
    cache
        .load(widget.path)
        .then(
          (bytes) {
            if (!mounted || request != _request) return;
            setState(() => _bytes = bytes);
          },
          onError: (Object e) {
            debugPrint('[ProofPhoto] load failed: $e');
            if (!mounted || request != _request) return;
            setState(() => _failed = true);
          },
        );
  }

  void _retry() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var source = widget.source;
    var takenAt = widget.takenAt;
    if (widget.showBadge && source == null && widget.resolveMetaFromAction) {
      final actionId = parseProofPhotoPath(widget.path)?.actionId;
      if (actionId != null) {
        final meta = ref.watch(proofActionMetaProvider(actionId)).value;
        if (meta?.proofPhotoPath == widget.path) {
          source = meta?.proofSource;
          takenAt = meta?.proofTakenAt;
        }
      }
    }
    final badge = widget.showBadge
        ? proofSourceBadgeLabel(
            l10n,
            source: ProofSource.fromId(source),
            takenAt: takenAt,
          )
        : null;
    final radius = BorderRadius.circular(widget.borderRadius);
    final compact = widget.height < 80;

    Widget child;
    if (_bytes != null) {
      child = GestureDetector(
        key: ValueKey('proof-photo-${widget.path}'),
        onTap: () => openProofPhotoViewer(
          context,
          path: widget.path,
          bytes: _bytes!,
          badge: badge,
          isOwner: widget.isOwner,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              _bytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) =>
                  _ErrorBox(label: compact ? null : l10n.proofPhotoLoadFailed),
            ),
            if (badge != null && !compact)
              Positioned(
                left: 8,
                bottom: 8,
                right: 8,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ProofBadgeChip(label: badge),
                ),
              ),
          ],
        ),
      );
    } else if (_failed) {
      child = InkWell(
        onTap: _retry,
        child: _ErrorBox(
          label: compact ? null : l10n.proofPhotoLoadFailed,
          action: compact ? null : l10n.proofPhotoRetry,
        ),
      );
    } else {
      child = ColoredBox(
        color: AppColors.primarySoft,
        child: Center(
          child: SizedBox(
            width: compact ? 16 : 24,
            height: compact ? 16 : 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: badge == null
          ? l10n.proofPhotoSemantics
          : '${l10n.proofPhotoSemantics}, $badge',
      image: true,
      button: _bytes != null,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: child,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({this.label, this.action});

  final String? label;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textDisabled,
              size: label == null ? 18 : 28,
            ),
            if (label != null) ...[
              const SizedBox(height: 6),
              Text(
                label!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 2),
              Text(
                action!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen, zoomable view of a proof photo.
Future<void> openProofPhotoViewer(
  BuildContext context, {
  required String path,
  required Uint8List bytes,
  String? badge,
  bool isOwner = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ProofPhotoViewer(
        path: path,
        bytes: bytes,
        badge: badge,
        isOwner: isOwner,
      ),
    ),
  );
}

enum _ViewerAction { report, disconnect, delete }

class ProofPhotoViewer extends ConsumerWidget {
  const ProofPhotoViewer({
    super.key,
    required this.path,
    required this.bytes,
    this.badge,
    this.isOwner = false,
  });

  final String path;
  final Uint8List bytes;
  final String? badge;
  final bool isOwner;

  /// The connected partner who owns this photo, if still connected.
  ConnectedUser? _owner(WidgetRef ref) {
    final ownerUid = parseProofPhotoPath(path)?.ownerUid;
    final profiles = ref.watch(connectedProfilesProvider).value ?? const [];
    for (final profile in profiles) {
      if (profile.user.uid == ownerUid) return profile;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final partner = isOwner ? null : _owner(ref);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          PopupMenuButton<_ViewerAction>(
            key: const ValueKey('proof-viewer-menu'),
            tooltip: l10n.proofViewerMenu,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => _onAction(context, ref, action, partner),
            itemBuilder: (context) => [
              if (isOwner)
                PopupMenuItem(
                  value: _ViewerAction.delete,
                  child: Text(l10n.proofViewerDelete),
                ),
              if (!isOwner)
                PopupMenuItem(
                  value: _ViewerAction.report,
                  child: Text(l10n.proofViewerReport),
                ),
              if (!isOwner && partner != null)
                PopupMenuItem(
                  value: _ViewerAction.disconnect,
                  child: Text(l10n.usDisconnectTooltip),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: ProofBadgeChip(label: badge!),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    _ViewerAction action,
    ConnectedUser? partner,
  ) async {
    switch (action) {
      case _ViewerAction.report:
        await _report(context, ref);
      case _ViewerAction.disconnect:
        if (partner == null) return;
        final done = await confirmAndDisconnectPartner(context, ref, partner);
        if (done && context.mounted) Navigator.of(context).maybePop();
      case _ViewerAction.delete:
        await _delete(context, ref);
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final actionId = parseProofPhotoPath(path)?.actionId ?? path;
    final uri = proofReportMailUri(
      actionId: actionId,
      subject: l10n.proofReportSubject,
      body: l10n.proofReportBody(actionId),
    );
    final opened = await ref.read(proofMailLauncherProvider)(uri);
    if (!opened) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.proofReportMailFailed(kSupportEmail))),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.proofDeleteConfirmTitle),
        content: Text(l10n.proofDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('proof-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.proofDeleteConfirm,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(recordRepositoryProvider).deleteProofPhoto(path);
      await ref.read(proofPhotoCacheProvider).evict(path);
      messenger?.showSnackBar(SnackBar(content: Text(l10n.proofDeleted)));
      if (navigator.mounted) navigator.maybePop();
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'proofDeleteUi');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.proofDeleteFailed)));
    }
  }
}
