import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/analytics.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../plan/domain/workout_template.dart';
import '../application/duo_recap_provider.dart';
import '../application/duo_stats_provider.dart';
import 'duo_share_card.dart';

/// Where the recap sheet was opened from (analytics `source`).
enum DuoRecapSource {
  /// The row on the Us tab.
  us('us'),

  /// Offered by itself at the start of a month.
  prompt('prompt');

  const DuoRecapSource(this.id);
  final String id;
}

/// The month's name the way the card says it: "11월", "November".
String recapMonthName(AppLocalizations l10n, DateTime month) =>
    DateFormat.MMMM(l10n.localeName).format(month);

/// One person's line on the recap card: "나 15일 · 🏃 러닝".
String recapPersonLine(
  AppLocalizations l10n,
  String name,
  int days,
  String? topWorkout,
) {
  final display = workoutDisplayFor(l10n, topWorkout);
  if (days == 0 || display == null) return l10n.recapPersonDays(name, days);
  return l10n.recapPersonDaysWorkout(
    name,
    days,
    '${display.emoji} ${display.name}',
  );
}

/// The 9:16 monthly recap card, laid out at [designSize] and exported at 3x
/// like the share card. It never carries a photo or my partner's real name —
/// they appear as the nickname I gave them, else 짝꿍.
class DuoRecapCard extends StatelessWidget {
  const DuoRecapCard({
    super.key,
    required this.recap,
    required this.meLabel,
    required this.partnerLabel,
  });

  static const Size designSize = DuoShareCard.designSize;

  final DuoRecap recap;
  final String meLabel;
  final String partnerLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final month = recapMonthName(l10n, recap.month);
    final today = recap.days.where((day) => day.isToday).firstOrNull;
    final soFar = today == null
        ? null
        : DateFormat.MMMd(l10n.localeName).format(today.date);

    return Semantics(
      label: l10n.recapSemantics,
      child: SizedBox.fromSize(
        size: designSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryPressed],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${recap.month.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  recap.hasPartner
                      ? l10n.recapTitleDuo(month)
                      : l10n.recapTitleSolo(month),
                  key: const ValueKey('recap-card-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    recap.hasPartner
                        ? l10n.recapHeadlineDuo(recap.duoDays)
                        : l10n.recapHeadlineSolo(recap.myDoneDays),
                    key: const ValueKey('recap-card-headline'),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                if (soFar != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.recapSoFar(soFar),
                    key: const ValueKey('recap-card-so-far'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _RecapCalendar(recap: recap, localeName: l10n.localeName),
                const SizedBox(height: 8),
                _legend(l10n),
                const Spacer(),
                for (final line in [
                  recapPersonLine(
                    l10n,
                    meLabel,
                    recap.myDoneDays,
                    recap.myTopWorkout,
                  ),
                  if (recap.hasPartner)
                    recapPersonLine(
                      l10n,
                      partnerLabel,
                      recap.partnerDoneDays,
                      recap.partnerTopWorkout,
                    ),
                  if (recap.bestStreak > 1)
                    l10n.recapBestStreak(recap.bestStreak),
                ]) ...[
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 12),
                Text(
                  l10n.shareCardStores,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(AppLocalizations l10n) {
    Widget item(Widget dot, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    return Row(
      children: [
        item(
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          recap.hasPartner ? l10n.recapLegendDuoDay : l10n.recapLegendSoloDay,
        ),
        if (recap.hasPartner) ...[
          const SizedBox(width: 14),
          item(
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            l10n.recapLegendOneOnly,
          ),
        ],
      ],
    );
  }
}

/// The month as a Monday-first grid: a filled dot on a headline day, a ring
/// when only one of the couple worked out.
class _RecapCalendar extends StatelessWidget {
  const _RecapCalendar({required this.recap, required this.localeName});

  final DuoRecap recap;
  final String localeName;

  static const double _rowHeight = 33;

  @override
  Widget build(BuildContext context) {
    // 2024-01-01 was a Monday.
    final weekdays = [
      for (var i = 0; i < 7; i++)
        DateFormat.EEEEE(localeName).format(DateTime(2024, 1, 1 + i)),
    ];
    // Days after today (only in the running month) are still to come.
    final today = recap.days.where((day) => day.isToday).firstOrNull?.date;
    final cells = <Widget>[
      for (var i = 1; i < recap.days.first.date.weekday; i++)
        const SizedBox.shrink(),
      for (final day in recap.days)
        _cell(day, isFuture: today != null && day.date.isAfter(today)),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        SizedBox(
          height: _rowHeight,
          child: Row(
            children: [
              for (var j = i; j < i + 7; j++)
                Expanded(
                  child: j < cells.length ? cells[j] : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      key: const ValueKey('recap-card-calendar'),
      children: [
        Row(
          children: [
            for (final label in weekdays)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ...rows,
      ],
    );
  }

  Widget _cell(DuoDay day, {required bool isFuture}) {
    final headline = !isFuture && recap.isHeadlineDay(day);
    final someone =
        !headline &&
        !isFuture &&
        (day.me.isDone || (recap.hasPartner && day.partner.isDone));
    return Center(
      child: Container(
        key: ValueKey(
          'recap-day-${day.date.day}-'
          '${headline
              ? 'full'
              : someone
              ? 'ring'
              : 'none'}',
        ),
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: headline ? Colors.white : null,
          border: someone ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        child: Text(
          '${day.date.day}',
          style: TextStyle(
            color: headline
                ? AppColors.primaryPressed
                : Colors.white.withValues(
                    alpha: someone
                        ? 1
                        : isFuture
                        ? 0.35
                        : 0.6,
                  ),
            fontSize: 12,
            fontWeight: headline || someone ? FontWeight.w800 : FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The sheet
// ---------------------------------------------------------------------------

/// Shows the monthly recap with [공유하기] / [다음에] and a month switcher,
/// opened on the month [monthsAgo] months back. Returns whether a card was
/// shared.
Future<bool> showDuoRecapSheet(
  BuildContext context,
  WidgetRef ref, {
  required DuoRecapSource source,
  int monthsAgo = 0,
}) async {
  final today = ref.read(duoTodayProvider);
  final month = recapMonthOf(today, monthsAgo: monthsAgo);
  final recap = ref.read(duoRecapProvider(month));
  AnalyticsService.log(AnalyticsEvent.recapOpened, {
    'source': source.id,
    'months_ago': monthsAgo,
    'days': recap?.headlineDays,
    'has_partner': recap?.hasPartner,
  });
  final shared = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DuoRecapSheet(source: source, initialMonth: month),
  );
  return shared ?? false;
}

class DuoRecapSheet extends ConsumerStatefulWidget {
  const DuoRecapSheet({
    super.key,
    required this.source,
    required this.initialMonth,
  });

  final DuoRecapSource source;

  /// The first day of the month shown first.
  final DateTime initialMonth;

  @override
  ConsumerState<DuoRecapSheet> createState() => _DuoRecapSheetState();
}

class _DuoRecapSheetState extends ConsumerState<DuoRecapSheet> {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  late DateTime _month = widget.initialMonth;
  bool _busy = false;

  Rect? _origin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  int _monthsAgo(DateTime today) =>
      (today.year - _month.year) * 12 + today.month - _month.month;

  Future<void> _share(DuoRecap recap) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final monthsAgo = _monthsAgo(ref.read(duoTodayProvider));
    try {
      final png = await ref.read(shareCardCaptureProvider)(_cardKey);
      final result = await ref
          .read(shareCardSharerProvider)
          .sharePng(png, text: l10n.shareCardText, origin: _origin());
      if (result.shared) {
        AnalyticsService.log(AnalyticsEvent.recapShared, {
          'target': result.target,
          'source': widget.source.id,
          'months_ago': monthsAgo,
          'days': recap.headlineDays,
          'has_partner': recap.hasPartner,
        });
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
    } catch (e) {
      debugPrint('[DuoRecapSheet] share failed: $e');
      messenger?.showSnackBar(SnackBar(content: Text(l10n.shareCardFailed)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final months = ref.watch(duoRecapMonthsProvider) ?? [_month];
    final recap = ref.watch(duoRecapProvider(_month));
    final label = ref.watch(partnerLabelProvider);
    // Newest first: the older month is the next index.
    final index = months.indexOf(_month);
    final older = index >= 0 && index + 1 < months.length
        ? months[index + 1]
        : null;
    final newer = index > 0 ? months[index - 1] : null;
    final previewHeight = (media.size.height * 0.54).clamp(200.0, 520.0);
    final canShare = recap != null && !recap.isEmpty && !_busy;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, media.viewPadding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.source == DuoRecapSource.prompt &&
                    _month == widget.initialMonth
                ? l10n.recapSheetTitleOffer(recapMonthName(l10n, _month))
                : l10n.recapSheetTitle,
            key: const ValueKey('recap-sheet-title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey('recap-prev-month'),
                tooltip: l10n.recapPrevMonth,
                onPressed: older == null || _busy
                    ? null
                    : () => setState(() => _month = older),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              SizedBox(
                width: 132,
                child: Text(
                  DateFormat.yMMMM(l10n.localeName).format(_month),
                  key: const ValueKey('recap-month-label'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('recap-next-month'),
                tooltip: l10n.recapNextMonth,
                onPressed: newer == null || _busy
                    ? null
                    : () => setState(() => _month = newer),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: previewHeight,
            child: recap == null
                ? const Center(child: CircularProgressIndicator())
                : FittedBox(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: DuoRecapCard(
                          recap: recap,
                          meLabel: l10n.duoMeLabel,
                          // The nickname is mine to share; the partner's
                          // real name is not.
                          partnerLabel:
                              normalizePartnerNickname(label.nickname) ??
                              l10n.partnerFallbackLabelStart,
                        ),
                      ),
                    ),
                  ),
          ),
          if (recap != null && recap.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.recapEmpty,
              key: const ValueKey('recap-sheet-empty'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: _shareButtonKey,
              onPressed: canShare ? () => _share(recap) : null,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(
                l10n.shareCardShare,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('recap-sheet-later'),
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text(l10n.shareCardLater),
          ),
        ],
      ),
    );
  }
}

/// The Us-tab row that opens the monthly recap. Hidden until I have a plan.
class DuoRecapEntry extends ConsumerWidget {
  const DuoRecapEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(myDuoPlansProvider);
    if (plans == null || plans.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final month = recapMonthOf(ref.watch(duoTodayProvider));

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const ValueKey('duo-recap-entry'),
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              showDuoRecapSheet(context, ref, source: DuoRecapSource.us),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.recapEntryTitle(recapMonthName(l10n, month)),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.recapEntrySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
