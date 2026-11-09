part of '../now_tab_screen.dart';

/// The primary card's text block: question, title, status lines, notes and
/// the promise / settlement details. Split out of primary_executor_card.dart.
extension _PrimaryExecutorMessage on _PrimaryExecutorCard {
  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    // 오늘 완료한 플랜이 둘 이상이면 체크리스트로 보여줘 성취의 규모가 드러나게 한다.
    if (model.state == HomeCardState.todayComplete &&
        model.completedPlans.length >= 2) {
      return _buildMultiPlanCompleteMessage(context, l10n);
    }

    final title = model.plan?.items.firstOrNull?.title;
    final List<Widget> children = [];
    final hero = _isCheckInHero;

    // 오늘 {운동} 했어? — the question leads; the promise line follows.
    if (hero) {
      children.add(
        Text(
          todayCheckInHeadline(l10n, model.plan!),
          key: const ValueKey('now-hero-question'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
          textAlign: TextAlign.left,
        ),
      );
      if (title != null) children.add(const SizedBox(height: 6));
    }

    // Title (if applicable)
    if (title != null) {
      children.add(
        Text(
          title,
          style: hero
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                )
              : Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
          textAlign: TextAlign.left,
        ),
      );

      // Description
      final description = model.plan?.items.firstOrNull?.description;
      if (description != null && description.isNotEmpty) {
        children.add(const SizedBox(height: 4));
        children.add(
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.left,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    }

    // 주 N회: 이번 주 2/3회 (or the goal-met line).
    final weeklyLine = hero ? todayCheckInWeeklyLine(l10n, model.plan!) : null;
    if (weeklyLine != null) {
      children.add(const SizedBox(height: 6));
      children.add(
        Text(
          weeklyLine,
          key: const ValueKey('now-hero-weekly'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    // 스트릭 배지
    if (model.streakCount != null && model.streakCount! >= 2) {
      children.add(const SizedBox(height: 8));
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.nowStreakCount(model.streakCount!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    String? statusMessage = model.headerMessage;
    // The partner was told about today's missing record: say who, by name.
    if (model.state == HomeCardState.poked && model.hasMissedNotice) {
      statusMessage = l10n.nowHeaderMissedNotice(
        model.partnerName ?? l10n.partnerFallbackLabel,
      );
    }
    String? subMessage; // Added for Type 2-1, 2-2 A/B, etc.

    if (statusMessage == null) {
      switch (model.state) {
        case HomeCardState.nowAction: // Type 1: 지금 실천
          // statusMessage = l10n.homeNowTask; // Removed per user request
          break;
        case HomeCardState.overdue: // Type 5: 지난 실천
          // statusMessage = l10n.timePassedActorMessage; // Removed per user request
          // subMessage = l10n.timePassedActorSubMessage;
          break;
        case HomeCardState.emptyPlan: // Type 2-1: 계획 필요
          statusMessage = l10n.nowNoPlan;
          subMessage = l10n.nowNoPlanSubtitle;
          break;
        case HomeCardState.todayComplete: // Type 2-2 A: 오늘 완료
          statusMessage = l10n.nowTodayDone;
          // Sub-message for next promise can be handled via upcoming schedule if available
          break;
        case HomeCardState.todayEmpty: // Type 2-2 B: 여유로운 날
          statusMessage = l10n.nowQuietRest;
          break;
        case HomeCardState.rejected: // Type 1-7: 반려됨
          statusMessage = l10n.nowHeaderAdjustNeeded;
          break;
        case HomeCardState.nextAction: // Type 1-3: 다음 일정 (이따·아무 때나)
          // The check-in hero asks the question itself.
          if (hero) break;
          final nt = model.plan?.items.firstOrNull?.notificationTime;
          final hasTime = nt != null && nt.type != 'none';
          statusMessage = hasTime
              ? l10n.nowNextActionLater
              : l10n.nowNextActionAnytime;
          break;
        case HomeCardState.poked:
          // 똑똑 배지에서 안내하므로 별도 statusMessage 없음
          break;
        case HomeCardState.promiseProposed:
          statusMessage = l10n.nowHeaderPromiseProposed;
          break;
        case HomeCardState.promiseSettled:
          statusMessage = l10n.nowHeaderPromiseSettled;
          break;
        case HomeCardState.pilotSettlement:
          statusMessage = l10n.nowHeaderSettlementNeeded;
          subMessage = l10n.nowHeaderSettlementSub;
          break;
        default:
          break;
      }
    }

    if (statusMessage != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(
        ReactionText(
          statusMessage,
          style:
              (title != null
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    color: title != null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    height: 1.5,
                  ),
          textAlign: TextAlign.left,
        ),
      );
    }

    // Render Sub-message if exists (e.g. for Plan Needed)
    if (subMessage != null) {
      children.add(const SizedBox(height: 4));
      children.add(
        Text(
          subMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }

    // My own proof photo once today's promise is recorded.
    if (model.state == HomeCardState.todayComplete) {
      final photoPath = todayProofPhotoPathOf(model.plan);
      if (photoPath != null) {
        children.add(const SizedBox(height: 12));
        children.add(
          ProofPhoto(
            key: ValueKey('own-proof-$photoPath'),
            path: photoPath,
            isOwner: true,
            resolveMetaFromAction: true,
            height: 200,
          ),
        );
      }
      // Close the loop: the partner's one-tap 인정 for today.
      final plan = model.plan;
      if (plan != null && _verifiedToday(plan)) {
        final reaction = plan.lastCheerType;
        children.add(const SizedBox(height: 10));
        children.add(
          Row(
            key: const ValueKey('now-partner-verified'),
            children: [
              if (reaction != null && ReactionIcon.assetFor(reaction) != null)
                ReactionIcon(reaction, size: 20)
              else
                Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.historyPartnerVerified,
                  style: TextStyle(
                    color: AppColors.primaryPressed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // ----------------------------------------------------
    // 1. lastActionNote (실천자 한마디 - 나/파트너 공통)
    // 날짜 라벨을 위에 붙여 "오늘은 ..."이 어제 작성된 메모임을 분명히 한다.
    // ----------------------------------------------------
    if (model.plan?.lastActionNote != null &&
        model.plan!.lastActionNote!.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(
        _buildDatedNoteBubble(
          context,
          l10n: l10n,
          text: model.plan!.lastActionNote!,
          date: _lastActionNoteDate(model.plan!),
          background: AppColors.background.withValues(alpha: 0.5),
          noteColor: AppColors.textPrimary,
          noteItalic: true,
          radius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(2),
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // 2. lastComment (매니저 피드백/응원)
    // lastCheerAt 기준으로 날짜 라벨을 붙인다.
    // lastCheerType(👍/❤️/💪 같은 리액션 이모지)과 lastComment를 나란히
    // 놓으면 ① 파트너가 보통 코멘트에도 이모지를 같이 치기 때문에 의미가
    // 중복되고 ② 두 Text의 fontSize/strut이 달라 윗선이 어긋난다.
    // ----------------------------------------------------
    if (model.plan?.lastComment != null &&
        model.plan!.lastComment!.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(
        _buildDatedNoteBubble(
          context,
          l10n: l10n,
          text: model.plan!.lastComment!,
          date: model.plan!.lastCheerAt,
          background: AppColors.primary.withValues(alpha: 0.1),
          noteColor: AppColors.primary,
          dateLabelColor: AppColors.primary.withValues(alpha: 0.75),
          noteWeight: FontWeight.w600,
          radius: BorderRadius.circular(12),
        ),
      );
    }

    // ----------------------------------------------------
    // 3. Promise 상세 (약속 제안/정산 결과)
    // ----------------------------------------------------
    if (model.plan?.promise != null) {
      final promise = model.plan!.promise!;
      if (model.state == HomeCardState.promiseProposed ||
          model.state == HomeCardState.promiseSettled) {
        children.add(const SizedBox(height: 12));
        children.add(_buildPromiseDetail(context, promise));
      }
    }

    if (model.state == HomeCardState.pilotSettlement && model.plan != null) {
      children.add(const SizedBox(height: 12));
      children.add(_buildPilotSettlementDetail(context, model.plan!));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static bool _verifiedToday(Plan plan) {
    final now = DateTime.now();
    return plan.verifiedDates.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }
}
