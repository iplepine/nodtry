import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/analytics.dart';
import '../../../../utils/error_reporter.dart';
import '../../application/partner_label_provider.dart';

/// The preset chips, in order. The first one (짝꿍) is picked by default.
List<String> partnerNicknamePresets(AppLocalizations l10n) => [
  l10n.nicknamePresetPartner,
  l10n.nicknamePresetJagi,
  l10n.nicknamePresetOppa,
  l10n.nicknamePresetYeobo,
  l10n.nicknamePresetAegi,
];

/// Lets me pick what to call my partner (`users/{me}.partnerNickname`).
///
/// Shown right after connecting ([celebrateName] adds "{name}하고
/// 연결됐어요 🎉" on top) and from the partner card in the Us tab.
Future<void> showPartnerNicknameSheet(
  BuildContext context, {
  String? celebrateName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => PartnerNicknameSheet(celebrateName: celebrateName),
  );
}

class PartnerNicknameSheet extends ConsumerStatefulWidget {
  const PartnerNicknameSheet({super.key, this.celebrateName});

  final String? celebrateName;

  @override
  ConsumerState<PartnerNicknameSheet> createState() =>
      _PartnerNicknameSheetState();
}

class _PartnerNicknameSheetState extends ConsumerState<PartnerNicknameSheet> {
  final TextEditingController _customController = TextEditingController();
  final FocusNode _customFocus = FocusNode();

  /// Index into the presets, or -1 for "직접 입력".
  int? _selected;
  bool _saving = false;

  static const int _custom = -1;

  @override
  void dispose() {
    _customController.dispose();
    _customFocus.dispose();
    super.dispose();
  }

  void _initSelection(List<String> presets, String? current) {
    if (_selected != null) return;
    if (current == null) {
      _selected = 0;
      return;
    }
    final index = presets.indexOf(current);
    if (index >= 0) {
      _selected = index;
    } else {
      _selected = _custom;
      _customController.text = current;
    }
  }

  String? _chosen(List<String> presets) {
    final selected = _selected ?? 0;
    if (selected == _custom) {
      return normalizePartnerNickname(_customController.text);
    }
    return presets[selected];
  }

  Future<void> _save(String? nickname, {required String kind}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(userRepositoryProvider).updatePartnerNickname(nickname);
      AnalyticsService.log(AnalyticsEvent.partnerNicknameSet, {'kind': kind});
      navigator.pop();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            nickname == null ? l10n.nicknameRemoved : l10n.nicknameSaved,
          ),
        ),
      );
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'updatePartnerNickname');
      if (mounted) setState(() => _saving = false);
      messenger?.showSnackBar(SnackBar(content: Text(l10n.nicknameSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = ref.watch(partnerLabelProvider);
    final presets = partnerNicknamePresets(l10n);
    _initSelection(presets, label.nickname);
    final shownName =
        partnerDisplayNameOrNull(label.displayName) ??
        l10n.partnerFallbackLabel;
    final chosen = _chosen(presets);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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
            if (widget.celebrateName != null) ...[
              Text(
                l10n.connectSuccessTitle(widget.celebrateName!),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              l10n.nicknameSheetTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.nicknameSheetBody(shownName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < presets.length; i++)
                  ChoiceChip(
                    key: ValueKey('nickname-chip-$i'),
                    label: Text(presets[i]),
                    selected: _selected == i,
                    onSelected: (_) {
                      setState(() => _selected = i);
                      _customFocus.unfocus();
                    },
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _selected == i
                          ? AppColors.primaryPressed
                          : AppColors.textPrimary,
                    ),
                  ),
                ChoiceChip(
                  key: const ValueKey('nickname-chip-custom'),
                  label: Text(l10n.nicknamePresetCustom),
                  selected: _selected == _custom,
                  onSelected: (_) {
                    setState(() => _selected = _custom);
                    _customFocus.requestFocus();
                  },
                  selectedColor: AppColors.primarySoft,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _selected == _custom
                        ? AppColors.primaryPressed
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (_selected == _custom) ...[
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('nickname-custom-field'),
                controller: _customController,
                focusNode: _customFocus,
                autofocus: true,
                textAlign: TextAlign.center,
                maxLength: kPartnerNicknameMaxLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kPartnerNicknameMaxLength),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.nicknameCustomHint,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const ValueKey('nickname-save'),
                onPressed: chosen == null || _saving
                    ? null
                    : () => _save(
                        chosen,
                        kind: _selected == _custom ? 'custom' : 'preset',
                      ),
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
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.nicknameSave),
              ),
            ),
            const SizedBox(height: 4),
            if (label.hasNickname)
              TextButton(
                key: const ValueKey('nickname-remove'),
                onPressed: _saving ? null : () => _save(null, kind: 'removed'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(l10n.nicknameRemove),
              )
            else
              TextButton(
                key: const ValueKey('nickname-later'),
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(l10n.nicknameLater),
              ),
          ],
        ),
      ),
    );
  }
}
