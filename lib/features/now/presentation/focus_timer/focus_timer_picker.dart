import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';

class FocusTimerPicker extends StatefulWidget {
  const FocusTimerPicker({super.key});

  @override
  State<FocusTimerPicker> createState() => _FocusTimerPickerState();
}

class _FocusTimerPickerState extends State<FocusTimerPicker> {
  static const List<int> _presets = [5, 10, 25];
  static const int _minMinutes = 1;
  static const int _maxMinutes = 120;

  int? _selectedPreset = 10;
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int? _resolveMinutes() {
    final raw = _customController.text.trim();
    if (raw.isNotEmpty) {
      final custom = int.tryParse(raw);
      if (custom != null && custom >= _minMinutes && custom <= _maxMinutes) {
        return custom;
      }
      return null;
    }
    return _selectedPreset;
  }

  void _confirm() {
    final minutes = _resolveMinutes();
    if (minutes == null) return;
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final systemNavInset = mediaQuery.viewPadding.bottom;
    final minutes = _resolveMinutes();

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + systemNavInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.focusTimerPickerTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.focusTimerPickerSubtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: _presets.map((m) {
                final isCustomActive = _customController.text.trim().isNotEmpty;
                final selected = !isCustomActive && _selectedPreset == m;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PresetChip(
                      label: l10n.focusTimerPresetMin(m),
                      selected: selected,
                      onTap: () {
                        setState(() {
                          _selectedPreset = m;
                          _customController.clear();
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.focusTimerCustomHint(_minMinutes, _maxMinutes),
                hintStyle: TextStyle(color: AppColors.textDisabled),
                suffixText: l10n.focusTimerMinuteUnit,
                filled: true,
                fillColor: AppColors.surface.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: minutes == null ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textDisabled,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                minutes == null
                    ? l10n.focusTimerPickFirst
                    : l10n.focusTimerStart(minutes),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? AppColors.primary.withValues(alpha: 0.12) : null,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.textDisabled,
          width: selected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
