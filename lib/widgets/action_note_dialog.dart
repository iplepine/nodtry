import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'centered_emoji.dart';

class ActionNoteDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? buttonLabel;
  final bool showEmoji;
  final String? initialText;

  const ActionNoteDialog({
    super.key,
    required this.title,
    this.hintText,
    this.buttonLabel,
    this.showEmoji = true,
    this.initialText,
  });

  @override
  State<ActionNoteDialog> createState() => _ActionNoteDialogState();
}

class _ActionNoteDialogState extends State<ActionNoteDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  String? _selectedEmoji;
  final List<String> _emojis = ['🔥', '❤️', '👏', '👍', '😮', '😢', '💪', '✨'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getResult() {
    final text = _controller.text.trim();
    if (_selectedEmoji != null && text.isNotEmpty) {
      return "$_selectedEmoji $text";
    }
    return _selectedEmoji ?? text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48;
    final maxDialogHeight = availableHeight
        .clamp(280.0, mediaQuery.size.height)
        .toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Emoji Selection
                if (widget.showEmoji) ...[
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: _emojis.map((emoji) {
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji = isSelected ? null : emoji;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CenteredEmoji(emoji, size: 22),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // TextField
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  minLines: 3,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintMaxLines: 2,
                    hintText: widget.hintText ?? "실천 소감을 남겨보세요 (선택)",
                    hintStyle: TextStyle(color: AppColors.textDisabled),
                    filled: true,
                    fillColor: AppColors.surface.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: TextStyle(color: AppColors.textDisabled),
                  ),
                  maxLength: 300,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 12), // Reduced since counter is there
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.cancel,
                            maxLines: 1,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _getResult()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.buttonLabel ?? l10n.homeDidIt,
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
