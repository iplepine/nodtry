import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';

/// 실천 기록을 캘린더 격자로 표시한다. plan.startDate ~ plan.endDate 구간을
/// 월별로 끊어 한 칸씩 (배경색 + 아이콘 + 테두리 패턴) 조합으로 상태를 나타낸다.
///
/// 색깔만으로 구분하면 시인성이 떨어진다는 피드백을 반영해, 성공/놓침은
/// 강한 대비 색 + 아이콘으로 또렷이 표시하고, 휴식·인정·건너뜀·예정은
/// 서로 다른 색조 또는 테두리 패턴으로 분기한다.
class PlanHistoryCalendarView extends StatelessWidget {
  final Plan plan;

  const PlanHistoryCalendarView({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final months = _monthsBetween(plan.startDate, plan.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(context),
        const SizedBox(height: 16),
        for (final month in months) ...[
          _MonthGrid(plan: plan, month: month),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [
        _legendItem(context, _DayStatus.done, l10n.planDetailLegendDone),
        _legendItem(context, _DayStatus.missed, l10n.planDetailLegendMissed),
        _legendItem(context, _DayStatus.rested, l10n.planDetailLegendRested),
        _legendItem(context, _DayStatus.rescued, l10n.planDetailLegendRescued),
        _legendItem(context, _DayStatus.skipped, l10n.planDetailLegendSkipped),
        _legendItem(
            context, _DayStatus.scheduled, l10n.planDetailLegendScheduled),
      ],
    );
  }

  Widget _legendItem(BuildContext context, _DayStatus status, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: _DayCell(
            day: null,
            status: status,
            compact: true,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  static List<DateTime> _monthsBetween(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var cursor = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }
}

class _MonthGrid extends StatelessWidget {
  final Plan plan;
  final DateTime month;

  const _MonthGrid({required this.plan, required this.month});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final today = _dateOnly(DateTime.now());

    final weekDayLabels = [
      l10n.planDetailDayMon,
      l10n.planDetailDayTue,
      l10n.planDetailDayWed,
      l10n.planDetailDayThu,
      l10n.planDetailDayFri,
      l10n.planDetailDaySat,
      l10n.planDetailDaySun,
    ];

    final scheduledWeekdays = plan.items.expand((i) => i.days).toSet();
    final start = _dateOnly(plan.startDate);
    final end = _dateOnly(plan.endDate);

    final children = <Widget>[];
    // Week header row
    for (final label in weekDayLabels) {
      children.add(
        Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    // Leading blanks before the first day
    for (var i = 1; i < firstWeekday; i++) {
      children.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final status = _classify(
        date: date,
        start: start,
        end: end,
        today: today,
        scheduledWeekdays: scheduledWeekdays,
      );
      children.add(_DayCell(day: day, status: status));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${month.year}.${month.month.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
          children: children,
        ),
      ],
    );
  }

  _DayStatus _classify({
    required DateTime date,
    required DateTime start,
    required DateTime end,
    required DateTime today,
    required Set<int> scheduledWeekdays,
  }) {
    if (date.isBefore(start) || date.isAfter(end)) {
      return _DayStatus.outside;
    }
    if (_containsDate(plan.completedDates, date)) return _DayStatus.done;
    if (_containsDate(plan.restedDates, date)) return _DayStatus.rested;
    if (_containsDate(plan.rescuedDates, date)) return _DayStatus.rescued;
    if (_containsDate(plan.skippedDates, date)) return _DayStatus.skipped;

    final isScheduled = scheduledWeekdays.isEmpty ||
        scheduledWeekdays.contains(date.weekday);
    if (!isScheduled) return _DayStatus.notScheduled;

    if (date.isBefore(today)) return _DayStatus.missed;
    return _DayStatus.scheduled;
  }
}

enum _DayStatus {
  done,
  rested,
  rescued,
  skipped,
  missed,
  scheduled,
  notScheduled,
  outside,
}

/// 셀 시각 표현 규약:
///
/// - **done**: mint 솔리드 + 흰색 ✓ 아이콘 + 흰색 굵은 숫자. "성공" 강한 양성 시그널.
/// - **missed**: coral(에러) 솔리드 + 흰색 ✕ 아이콘 + 흰색 굵은 숫자. "안 한 것" 강한 음성 시그널.
/// - **rested**: 시안톤 솔리드 + 흰색 달 아이콘. 휴식권 사용 — 다른 색조로 분리.
/// - **rescued**: 흰 배경 + mint 테두리(2px) + mint 작은 ✓. "파트너 인정" — done의 약한 버전.
/// - **skipped**: 옅은 회색 솔리드 + 회색 빗금 아이콘 + 취소선 숫자.
/// - **scheduled**: 옅은 mint 점선 테두리 + 보통 숫자. "예정/미래".
/// - **notScheduled**: 배경/테두리 없음. 매우 옅은 숫자만.
/// - **outside**: notScheduled와 동일 (플랜 기간 밖).
class _DayCell extends StatelessWidget {
  final int? day;
  final _DayStatus status;
  final bool compact;

  const _DayCell({
    required this.day,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = _visualsFor(status);
    final numberStyle = TextStyle(
      color: visuals.textColor,
      fontWeight: visuals.bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: compact ? 9 : 12,
      decoration:
          visuals.strikethrough ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: visuals.textColor.withValues(alpha: 0.8),
      decorationThickness: 2,
    );

    final iconSize = compact ? 9.0 : 12.0;
    final showIcon = visuals.icon != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.fill,
        borderRadius: BorderRadius.circular(6),
        border: visuals.border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (day != null)
            Text('$day', style: numberStyle)
          else if (showIcon)
            // 범례에서는 숫자 없이 아이콘만 가운데에 보여준다.
            Icon(visuals.icon, size: iconSize, color: visuals.iconColor),
          if (day != null && showIcon)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                visuals.icon,
                size: iconSize,
                color: visuals.iconColor,
              ),
            ),
        ],
      ),
    );
  }

  static _DayVisuals _visualsFor(_DayStatus status) {
    switch (status) {
      case _DayStatus.done:
        return _DayVisuals(
          fill: AppColors.primary,
          textColor: Colors.white,
          icon: Icons.check,
          iconColor: Colors.white,
          bold: true,
        );
      case _DayStatus.missed:
        return _DayVisuals(
          fill: AppColors.error,
          textColor: Colors.white,
          icon: Icons.close,
          iconColor: Colors.white,
          bold: true,
        );
      case _DayStatus.rested:
        return _DayVisuals(
          fill: const Color(0xFF7AB8C8), // 시안톤 — mint와 다른 색조
          textColor: Colors.white,
          icon: Icons.nightlight_round,
          iconColor: Colors.white,
        );
      case _DayStatus.rescued:
        return _DayVisuals(
          fill: Colors.transparent,
          textColor: AppColors.primary,
          icon: Icons.check,
          iconColor: AppColors.primary,
          bold: true,
          border: Border.all(color: AppColors.primary, width: 2),
        );
      case _DayStatus.skipped:
        return _DayVisuals(
          fill: AppColors.textDisabled.withValues(alpha: 0.25),
          textColor: AppColors.textSecondary,
          icon: Icons.remove,
          iconColor: AppColors.textSecondary,
          strikethrough: true,
        );
      case _DayStatus.scheduled:
        return _DayVisuals(
          fill: Colors.transparent,
          textColor: AppColors.textSecondary,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.45),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
            style: BorderStyle.solid,
          ),
        );
      case _DayStatus.notScheduled:
      case _DayStatus.outside:
        return _DayVisuals(
          fill: Colors.transparent,
          textColor: AppColors.textDisabled.withValues(alpha: 0.6),
        );
    }
  }
}

class _DayVisuals {
  final Color fill;
  final Color textColor;
  final IconData? icon;
  final Color iconColor;
  final bool bold;
  final bool strikethrough;
  final BoxBorder? border;

  const _DayVisuals({
    required this.fill,
    required this.textColor,
    this.icon,
    this.iconColor = Colors.transparent,
    this.bold = false,
    this.strikethrough = false,
    this.border,
  });
}

/// 주별 실천율을 막대 그래프로 표시한다.
class PlanHistoryGraphView extends StatelessWidget {
  final Plan plan;

  const PlanHistoryGraphView({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weeks = _weeklyStats(plan);

    if (weeks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.planDetailGraphEmpty,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planDetailGraphCompletionRate,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < weeks.length; i++)
                Expanded(
                  child: _WeekBar(
                    weekIndex: i + 1,
                    stats: weeks[i],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 플랜 기간을 시작일 기준 7일 단위 주차로 묶는다.
  static List<_WeekStats> _weeklyStats(Plan plan) {
    final start = _dateOnly(plan.startDate);
    final end = _dateOnly(plan.endDate);
    if (end.isBefore(start)) return const [];

    final scheduledWeekdays = plan.items.expand((i) => i.days).toSet();
    final today = _dateOnly(DateTime.now());
    final cutoff = today.isAfter(end) ? end : today;

    final weeks = <_WeekStats>[];
    var weekStart = start;
    while (!weekStart.isAfter(end)) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final effectiveEnd = weekEnd.isAfter(end) ? end : weekEnd;
      int scheduled = 0;
      int done = 0;
      var day = weekStart;
      while (!day.isAfter(effectiveEnd)) {
        final isScheduled = scheduledWeekdays.isEmpty ||
            scheduledWeekdays.contains(day.weekday);
        if (isScheduled && !day.isAfter(cutoff)) {
          scheduled++;
          if (_containsDate(plan.completedDates, day) ||
              _containsDate(plan.rescuedDates, day) ||
              _containsDate(plan.restedDates, day)) {
            done++;
          }
        }
        day = day.add(const Duration(days: 1));
      }
      weeks.add(_WeekStats(scheduled: scheduled, done: done));
      weekStart = weekStart.add(const Duration(days: 7));
    }
    return weeks;
  }
}

class _WeekStats {
  final int scheduled;
  final int done;
  const _WeekStats({required this.scheduled, required this.done});

  double get ratio {
    if (scheduled == 0) return 0;
    return done / scheduled;
  }
}

class _WeekBar extends StatelessWidget {
  final int weekIndex;
  final _WeekStats stats;

  const _WeekBar({required this.weekIndex, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasData = stats.scheduled > 0;
    final ratio = stats.ratio;
    final percentText = hasData ? '${(ratio * 100).round()}%' : '–';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            percentText,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barHeight = constraints.maxHeight * ratio;
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.textDisabled.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: barHeight.clamp(2.0, constraints.maxHeight),
                      decoration: BoxDecoration(
                        color: hasData
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.planDetailWeekLabel(weekIndex),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _containsDate(List<DateTime> dates, DateTime target) {
  return dates.any(
    (d) => d.year == target.year && d.month == target.month && d.day == target.day,
  );
}
