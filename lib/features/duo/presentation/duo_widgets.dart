import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../domain/duo_stats.dart';

/// The status word for one person's day ("완료 ✓", "인정 ❤️", "아직" …).
String duoStatusLabel(AppLocalizations l10n, DuoPersonDay day) {
  switch (day.status) {
    case DuoDayStatus.done:
      switch (day.verification) {
        case DuoVerification.verified:
          return l10n.duoStatusVerified;
        case DuoVerification.waiting:
          return l10n.duoStatusWaiting;
        case DuoVerification.none:
          return l10n.duoStatusDone;
      }
    case DuoDayStatus.pending:
      return l10n.duoStatusPending;
    case DuoDayStatus.rested:
      return l10n.duoStatusRested;
    case DuoDayStatus.off:
      return l10n.duoStatusOff;
    case DuoDayStatus.missed:
      return l10n.duoStatusMissed;
    case DuoDayStatus.upcoming:
      return l10n.duoStatusUpcoming;
  }
}

/// "둘이 함께 N일째", or the day-one nudge while there is no streak.
String duoStreakHeadline(AppLocalizations l10n, int streak) =>
    streak > 0 ? l10n.duoStreakDays(streak) : l10n.duoStreakStart;

/// A round avatar: the profile photo, else the first letter of [name].
class DuoAvatar extends StatelessWidget {
  const DuoAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 18,
  });

  final String? imageUrl;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final Widget avatar = (url != null && url.isNotEmpty)
        ? CachedNetworkImage(
            imageUrl: url,
            imageBuilder: (context, image) =>
                CircleAvatar(radius: radius, backgroundImage: image),
            placeholder: (context, _) => CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.primarySoft,
            ),
            errorWidget: (context, url, error) => _initial(),
          )
        : _initial();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: avatar,
    );
  }

  Widget _initial() {
    final trimmed = name?.trim() ?? '';
    final initial = trimmed.isEmpty
        ? null
        : String.fromCharCode(trimmed.runes.first);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      child: initial == null
          ? Icon(
              Icons.person_rounded,
              size: radius,
              color: AppColors.primaryPressed,
            )
          : Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPressed,
              ),
            ),
    );
  }
}

/// Two overlapping avatars: me, then my partner.
class DuoAvatarPair extends StatelessWidget {
  const DuoAvatarPair({
    super.key,
    required this.myImageUrl,
    required this.myName,
    required this.partnerImageUrl,
    required this.partnerName,
    this.radius = 18,
  });

  final String? myImageUrl;
  final String? myName;
  final String? partnerImageUrl;
  final String? partnerName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2 + 4; // avatar + border
    return SizedBox(
      width: size * 1.8,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: DuoAvatar(
              imageUrl: myImageUrl,
              name: myName,
              radius: radius,
            ),
          ),
          Positioned(
            left: size * 0.8,
            child: DuoAvatar(
              imageUrl: partnerImageUrl,
              name: partnerName,
              radius: radius,
            ),
          ),
        ],
      ),
    );
  }
}

/// "{name} {status}" pill for one person's day.
class DuoStatusChip extends StatelessWidget {
  const DuoStatusChip({
    super.key,
    required this.name,
    required this.day,
    required this.color,
  });

  final String name;
  final DuoPersonDay day;

  /// The person's colour (me: primary, partner: secondary).
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strong = day.isDone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: strong
            ? color.withValues(alpha: 0.16)
            : AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: strong ? color : AppColors.outline.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        l10n.duoPersonStatus(name, duoStatusLabel(l10n, day)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// The Now tab's header when a partner is connected (spec §4.7): two
/// avatars, "둘이 함께 N일째" and today's status for each of us — or
/// "오늘 둘운완이에요 🎉" once today is a duo day.
class DuoStreakHeader extends StatelessWidget {
  const DuoStreakHeader({
    super.key,
    required this.stats,
    required this.myName,
    required this.myImageUrl,
    required this.partnerName,
    required this.partnerImageUrl,
  });

  final DuoStats stats;
  final String? myName;
  final String? myImageUrl;
  final String partnerName;
  final String? partnerImageUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final today = stats.today;
    return Container(
      key: const ValueKey('duo-header'),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: statusBarHeight + 10,
        bottom: 10,
      ),
      child: Row(
        children: [
          DuoAvatarPair(
            myImageUrl: myImageUrl,
            myName: myName,
            partnerImageUrl: partnerImageUrl,
            partnerName: partnerName,
            radius: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  duoStreakHeadline(l10n, stats.streak),
                  key: const ValueKey('duo-header-streak'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (stats.todayIsDuoDone)
                  Text(
                    l10n.duoTodayDone,
                    key: const ValueKey('duo-header-today-done'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      DuoStatusChip(
                        key: const ValueKey('duo-header-me'),
                        name: l10n.duoMeLabel,
                        day: today.me,
                        color: AppColors.primary,
                      ),
                      DuoStatusChip(
                        key: const ValueKey('duo-header-partner'),
                        name: partnerName,
                        day: today.partner,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// This week's dots (Mon–Sun): one row for me, one for my partner, and the
/// duo days highlighted behind both. Done is a filled dot (❤️ inside when
/// 인정 came), a rest pass a soft dot, a miss a small ×, today an outlined
/// ring until it is recorded.
class DuoWeekDots extends StatelessWidget {
  const DuoWeekDots({
    super.key,
    required this.week,
    required this.showPartner,
    this.meLabel,
    this.partnerLabel,
  });

  final List<DuoDay> week;
  final bool showPartner;

  /// Row labels; when null the rows are unlabeled.
  final String? meLabel;
  final String? partnerLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekday = DateFormat('E', l10n.localeName);
    final labelled = meLabel != null;

    Widget rowLabel(String? text) => labelled
        ? SizedBox(
            width: 44,
            child: Text(
              text ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelled)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              SizedBox(height: 22, child: Center(child: rowLabel(meLabel))),
              if (showPartner)
                SizedBox(
                  height: 22,
                  child: Center(child: rowLabel(partnerLabel)),
                ),
            ],
          ),
        for (final day in week)
          Expanded(
            child: Semantics(
              label: l10n.duoDaySemantics(
                weekday.format(day.date),
                duoStatusLabel(l10n, day.me),
                duoStatusLabel(l10n, day.partner),
              ),
              excludeSemantics: true,
              child: Container(
                key: ValueKey(
                  'duo-week-${day.date.month}-${day.date.day}'
                  '${day.isDuoDay ? '-duo' : ''}',
                ),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                padding: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: day.isDuoDay
                      ? AppColors.primarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 22,
                      child: Center(
                        child: Text(
                          weekday.format(day.date),
                          style: TextStyle(
                            color: day.isToday
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                            fontSize: 11,
                            fontWeight: day.isToday
                                ? FontWeight.w800
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 22,
                      child: Center(
                        child: _DuoDot(
                          day: day.me,
                          isToday: day.isToday,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (showPartner)
                      SizedBox(
                        height: 22,
                        child: Center(
                          child: _DuoDot(
                            day: day.partner,
                            isToday: day.isToday,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DuoDot extends StatelessWidget {
  const _DuoDot({
    required this.day,
    required this.isToday,
    required this.color,
  });

  final DuoPersonDay day;
  final bool isToday;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 14.0;
    switch (day.status) {
      case DuoDayStatus.done:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: day.verification == DuoVerification.verified
              ? const Icon(Icons.favorite, size: 8, color: Colors.white)
              : null,
        );
      case DuoDayStatus.rested:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        );
      case DuoDayStatus.missed:
        return Icon(
          Icons.close_rounded,
          size: 12,
          color: AppColors.textDisabled,
        );
      case DuoDayStatus.pending:
      case DuoDayStatus.upcoming:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isToday
                  ? color.withValues(alpha: 0.7)
                  : AppColors.outline.withValues(alpha: 0.7),
              width: isToday ? 1.5 : 1,
            ),
          ),
        );
      case DuoDayStatus.off:
        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textDisabled.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
