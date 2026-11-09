import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/error_reporter.dart';

/// The settings switch for `users/{me}.allowPartnerPhotoInShareCard`: may my
/// partner put my 인증샷 on the share cards they make (the together layout)?
/// Missing reads as off.
class SharePhotoConsentTile extends ConsumerStatefulWidget {
  const SharePhotoConsentTile({super.key});

  @override
  ConsumerState<SharePhotoConsentTile> createState() =>
      _SharePhotoConsentTileState();
}

class _SharePhotoConsentTileState extends ConsumerState<SharePhotoConsentTile> {
  /// What I just picked, shown until the profile stream catches up.
  bool? _pending;
  bool _saving = false;

  Future<void> _set(bool allow) async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _pending = allow;
      _saving = true;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .updateAllowPartnerPhotoInShareCard(allow);
      if (!mounted) return;
      setState(() => _saving = false);
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'updateAllowPartnerPhotoInShareCard');
      if (!mounted) return;
      setState(() {
        _pending = null;
        _saving = false;
      });
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.sharePhotoConsentSaveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stored = ref.watch(
      myProfileProvider.select(
        (profile) => profile.value?.allowsPartnerPhotoInShareCard ?? false,
      ),
    );
    final value = _pending ?? stored;

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider, width: 1),
      ),
      child: SwitchListTile.adaptive(
        key: const ValueKey('settings-share-photo-consent'),
        value: value,
        onChanged: _saving ? null : _set,
        activeTrackColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          l10n.sharePhotoConsentSettingTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.sharePhotoConsentSettingHelper,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
