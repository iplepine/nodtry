import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/legal_links.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// "…이용약관에 동의하는 거예요" with a link to the terms of use, shown where
/// partner-to-partner content starts (connecting, sending an invite, the first
/// proof photo). The terms say there is no tolerance for objectionable
/// content or abusive users (Guideline 1.2).
class TermsNotice extends ConsumerWidget {
  const TermsNotice({super.key, required this.text});

  /// The agreement line for this moment (connect / invite / photo).
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('terms-notice'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          key: const ValueKey('terms-notice-link'),
          onPressed: () =>
              ref.read(externalLinkLauncherProvider)(Uri.parse(kTermsOfUseUrl)),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.termsViewLink,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
