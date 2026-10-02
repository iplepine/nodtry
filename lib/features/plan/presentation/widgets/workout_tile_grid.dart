import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/workout_template.dart';

/// The workout tiles of the plan-create screen: emoji + label, 3 per row.
///
/// Rows size to their tallest tile, so a two-line label (식단·야식 참기) or a
/// large text setting never clips.
class WorkoutTileGrid extends StatelessWidget {
  static const columns = 3;
  static const _gap = 8.0;

  final List<WorkoutTemplate> templates;
  final WorkoutType? selected;
  final ValueChanged<WorkoutTemplate> onSelected;

  const WorkoutTileGrid({
    super.key,
    required this.templates,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <List<WorkoutTemplate>>[
      for (var i = 0; i < templates.length; i += columns)
        templates.sublist(
          i,
          i + columns > templates.length ? templates.length : i + columns,
        ),
    ];

    return Column(
      children: [
        for (final (rowIndex, row) in rows.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: rowIndex == rows.length - 1 ? 0 : _gap,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: column < row.length
                          ? _WorkoutTile(
                              key: ValueKey('workout-tile-${row[column].id}'),
                              template: row[column],
                              isSelected: row[column].type == selected,
                              onTap: () => onSelected(row[column]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final WorkoutTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkoutTile({
    super.key,
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
        width: isSelected ? 2 : 1,
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.primarySoft : AppColors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Text(
                    template.emoji,
                    style: const TextStyle(fontSize: 26, height: 1.1),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  template.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
