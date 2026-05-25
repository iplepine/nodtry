import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/plan_model.dart';
import '../../../../theme/app_colors.dart';

/// 실천 기록을 캘린더 격자로 표시한다. plan.startDate ~ plan.endDate 구간을
/// 월별로 끊어 한 칸씩 색으로 상태를 나타낸다.
class PlanHistoryCalendarView extends StatelessWidget {
  final Plan plan;

  const PlanHistoryCalendarView({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final months = _monthsBetween(plan.startDate, plan.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(context, l10n),
        const SizedBox(height: 16),
        for (final month in months) ...[
          _MonthGrid(plan: plan, month: month),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildLegend(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendItem(context, AppColors.primary, l10n.planDetailLegendDone),
        _legendItem(context, AppColors.secondary, l10n.planDetailLegendRested),
        _legendItem(
          context,
          AppColors.secondary.withValues(alpha: 0.6),
          l10n.planDetailLegendRescued,
        ),
        _legendItem(
          context,
          AppColors.textDisabled.withValues(alpha: 0.6),
          l10n.planDetailLegendSkipped,
        ),
        _legendItem(context, AppColors.error.withValues(alpha: 0.5),
            l10n.planDetailLegendMissed),
        _legendItem(
          context,
          AppColors.textDisabled.withValues(alpha: 0.2),
          l10n.planDetailLegendScheduled,
        ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
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
      children.add(_DayCell(day: day, status: status, date: date));
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

class _DayCell extends StatelessWidget {
  final int day;
  final _DayStatus status;
  final DateTime date;

  const _DayCell({
    required this.day,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final color = _backgroundColor();
    final textColor = _textColor();

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _backgroundColor() {
    switch (status) {
      case _DayStatus.done:
        return AppColors.primary;
      case _DayStatus.rested:
        return AppColors.secondary;
      case _DayStatus.rescued:
        return AppColors.secondary.withValues(alpha: 0.6);
      case _DayStatus.skipped:
        return AppColors.textDisabled.withValues(alpha: 0.6);
      case _DayStatus.missed:
        return AppColors.error.withValues(alpha: 0.5);
      case _DayStatus.scheduled:
        return AppColors.textDisabled.withValues(alpha: 0.2);
      case _DayStatus.notScheduled:
      case _DayStatus.outside:
        return Colors.transparent;
    }
  }

  Color _textColor() {
    switch (status) {
      case _DayStatus.done:
      case _DayStatus.rested:
      case _DayStatus.rescued:
      case _DayStatus.missed:
        return Colors.white;
      case _DayStatus.skipped:
        return AppColors.textPrimary;
      case _DayStatus.scheduled:
        return AppColors.textSecondary;
      case _DayStatus.notScheduled:
      case _DayStatus.outside:
        return AppColors.textDisabled;
    }
  }
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
