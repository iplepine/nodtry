import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/partner_label.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/user_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/terms_notice.dart';

/// A round profile picture, or the first letter of [name] on a soft tint.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 32,
  });

  final String? imageUrl;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final fallback = _initial();
    if (url == null || url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, image) =>
          CircleAvatar(radius: radius, backgroundImage: image),
      placeholder: (context, _) => fallback,
      errorWidget: (context, _, _) => fallback,
    );
  }

  Widget _initial() {
    final trimmed = name?.trim();
    final letter = trimmed == null || trimmed.isEmpty
        ? null
        : String.fromCharCode(trimmed.runes.first);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: letter == null
          ? Icon(
              Icons.person_rounded,
              size: radius,
              color: AppColors.primaryPressed,
            )
          : Text(
              letter,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryPressed,
              ),
            ),
    );
  }
}

/// "{이름}의 운동 약속을 봐줄래요?" with the code owner's picture and a
/// [내가 봐줄게] button. Resolves to true when the user confirms.
Future<bool> showInviteConfirmSheet(
  BuildContext context, {
  required UserModel owner,
  bool fromClipboard = false,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) =>
        InviteConfirmSheet(owner: owner, fromClipboard: fromClipboard),
  );
  return confirmed == true;
}

class InviteConfirmSheet extends StatelessWidget {
  const InviteConfirmSheet({
    super.key,
    required this.owner,
    this.fromClipboard = false,
  });

  final UserModel owner;

  /// Adds "복사해 둔 초대 코드를 찾았어요" above the question.
  final bool fromClipboard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name =
        partnerDisplayNameOrNull(owner.displayName) ??
        l10n.partnerFallbackLabel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
            if (fromClipboard) ...[
              Text(
                l10n.connectInviteCodeDetectedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Center(
              child: PersonAvatar(
                imageUrl: owner.profileImageUrl,
                name: name,
                radius: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.connectConfirmTitle(name),
              key: const ValueKey('invite-confirm-title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.connectConfirmBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TermsNotice(text: l10n.termsNoticeConnect),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('invite-confirm-accept'),
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(l10n.connectConfirmAccept),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const ValueKey('invite-confirm-cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text(l10n.connectCancel),
            ),
          ],
        ),
      ),
    );
  }
}
