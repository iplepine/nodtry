part of '../now_tab_screen.dart';

/// The 지금 tab's header and the time-chip texts for its cards. Split out of
/// now_tab_screen.dart.
extension _NowTabHeaderAndChips on _NowTabState {
  /// The duo header (two avatars, "둘이 함께 N일째", today's status for both)
  /// once a partner is connected and the stats are in; the quiet header
  /// otherwise.
  Widget _buildHeader(NowTabState uiState) {
    final partner = uiState.partnerProfile;
    final label = ref.watch(partnerLabelProvider);
    final stats = ref.watch(duoStatsProvider);
    if (partner != null && stats != null && stats.hasPartner) {
      final me = ref.watch(myProfileProvider).value;
      return DuoStreakHeader(
        stats: stats,
        myName: me?.displayName,
        myImageUrl: me?.profileImageUrl,
        // Starts the status pill ("{name} 아직"): the capitalized fallback.
        partnerName:
            label.preferredFor(partner.uid, displayName: partner.displayName) ??
            AppLocalizations.of(context)!.partnerFallbackLabelStart,
        partnerImageUrl: partner.profileImageUrl,
      );
    }
    return QuietHeader(
      partnerName: partner == null
          ? null
          : label.preferredFor(partner.uid, displayName: partner.displayName),
      periodState: uiState.headerPeriodState,
      onSettingsTap: null,
    );
  }

  /// Time Chip 텍스트 가져오기

  /// 정확한 시간 텍스트 가져오기 (롱 프레스용)
  String? _getExactTimeText(HomeCardModel model) {
    if (model.state == HomeCardState.overdue) {
      // 과거 미완료(Type 5)의 경우 정확한 시간보다는 상태가 중요하므로 null 반환 또는 별도 처리
      return null;
    }

    if (model.plan != null && model.plan!.items.isNotEmpty) {
      for (var item in model.plan!.items) {
        if (item.notificationTime != null &&
            item.notificationTime!.type != 'none') {
          final now = DateTime.now();
          final scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            item.notificationTime!.hour,
            item.notificationTime!.minute,
          );

          final exactTime = TimeFormatter.formatExactTime(scheduledTime);
          final diff = scheduledTime.difference(now);
          final absDiff = diff.abs();

          final l10n = AppLocalizations.of(context)!;
          String suffix;
          if (diff.isNegative) {
            if (absDiff.inMinutes < 60) {
              suffix = l10n.nowTimeMinBeforeAlert(absDiff.inMinutes);
            } else {
              suffix = l10n.nowTimeHourBeforeAlert(absDiff.inHours);
            }
          } else {
            if (absDiff.inMinutes < 60) {
              suffix = l10n.nowTimeMinAfterAlert(absDiff.inMinutes);
            } else {
              suffix = l10n.nowTimeHourAfterAlert(absDiff.inHours);
            }
          }

          return '$exactTime · $suffix';
        }
      }
    }
    return null;
  }

  /// Time Chip 텍스트 가져오기 (Vague Time 적용)
  String? _getTimeChipText(HomeCardModel model) {
    if (model.state == HomeCardState.overdue) {
      return overdueTimeChipText(
        AppLocalizations.of(context)!,
        model.plan,
        now: DateTime.now(),
      );
    }

    if (model.plan != null && model.plan!.items.isNotEmpty) {
      for (var item in model.plan!.items) {
        if (item.notificationTime != null &&
            item.notificationTime!.type != 'none') {
          final now = DateTime.now();
          DateTime dateBase = now;
          if (model.plan != null && model.plan!.startDate.isAfter(now)) {
            dateBase = model.plan!.startDate;
          }

          final scheduledTime = DateTime(
            dateBase.year,
            dateBase.month,
            dateBase.day,
            item.notificationTime!.hour,
            item.notificationTime!.minute,
          );

          // 정확한 시간 표시 (예: "20:00")
          final timeText = TimeFormatter.formatExactTime(scheduledTime);
          final l10n = AppLocalizations.of(context)!;

          // 날짜 비교
          final today = DateTime(now.year, now.month, now.day);
          final scheduledDate = DateTime(
            scheduledTime.year,
            scheduledTime.month,
            scheduledTime.day,
          );
          final diffDays = scheduledDate.difference(today).inDays;

          String displayText = timeText;
          if (diffDays == 1) {
            displayText = '${l10n.timeChipTomorrow} $timeText';
          } else if (diffDays > 1) {
            displayText =
                '${scheduledTime.month}.${scheduledTime.day} $timeText';
          }

          if (model.state == HomeCardState.nowAction) {
            final isToday = diffDays == 0;
            final isPast = now.isAfter(scheduledTime);

            if (isToday) {
              if (isPast) {
                // 이미 시간이 지난 경우: 안심시키는 메시지
                return '$displayText · ${l10n.comfortingLate}';
              } else {
                // 아직 시간이 남은 경우: 응원 메시지
                return '$displayText · ${l10n.comfortingFuture}';
              }
            }
          }
          return displayText;
        }
      }
    }
    // 시간 미지정 nextAction은 "오늘 아무 때나"로 안내(시간 압박 없음).
    if (model.state == HomeCardState.nextAction) {
      return AppLocalizations.of(context)!.timeChipAnytime;
    }
    return null;
  }

  /// Time Chip 타입 — 카드 상태로 정한다. 칩 문구(번역문)는 해석하지 않는다.
  TimeChipType? _getTimeChipType(HomeCardModel model) {
    return timeChipTypeFor(
      model.state,
      hasChipText: _getTimeChipText(model) != null,
    );
  }
}
