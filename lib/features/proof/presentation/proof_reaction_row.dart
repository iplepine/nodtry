import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/proof_photo.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_underlined_text.dart';
import '../../../widgets/reaction_icon.dart';

/// One-tap 인정: ❤️🔥💪👏. A tap verifies the record and sends that emoji;
/// "한마디" opens the optional note dialog instead.
class ProofReactionRow extends StatelessWidget {
  const ProofReactionRow({
    super.key,
    required this.onReact,
    this.onAddNote,
    this.showHint = true,
    this.iconSize = 28,
  });

  final ValueChanged<String>? onReact;
  final VoidCallback? onAddNote;
  final bool showHint;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHint) ...[
          Text(
            l10n.nowReactHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            for (final emoji in kProofReactions) ...[
              if (emoji != kProofReactions.first) const SizedBox(width: 8),
              Expanded(
                child: _ReactionButton(
                  key: ValueKey('react-$emoji'),
                  emoji: emoji,
                  size: iconSize,
                  semanticLabel: l10n.nowReactSemantics(emoji),
                  onTap: onReact == null ? null : () => onReact!(emoji),
                ),
              ),
            ],
          ],
        ),
        if (onAddNote != null) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              key: const ValueKey('react-add-note'),
              onPressed: onAddNote,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: AppUnderlinedText(
                      l10n.nowReactAddNote,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    super.key,
    required this.emoji,
    required this.size,
    required this.semanticLabel,
    this.onTap,
  });

  final String emoji;
  final double size;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: size + 24,
            child: ReactionIcon(emoji, size: size),
          ),
        ),
      ),
    );
  }
}
