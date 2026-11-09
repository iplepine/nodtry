part of '../now_tab_screen.dart';

/// My own record actions on the 지금 tab: 했어 (with or without a photo), the
/// focus timer, rest / skip / defer and the plan create / modify jumps.
/// Split out of now_tab_screen.dart.
extension _NowTabRecordActions on _NowTabState {
  Future<void> _handleDidIt() async {
    final primaryCard = _activePrimaryCard();
    if (primaryCard == null) return;
    await _handleDidItForCard(primaryCard);
  }

  Future<void> _handleFocusTimer() async {
    final primaryCard = _activePrimaryCard();
    if (primaryCard == null || primaryCard.plan?.id == null) return;

    final minutes = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FocusTimerPicker(),
    );
    if (minutes == null || !mounted) return;

    final planTitle = primaryCard.plan?.items.firstOrNull?.title;
    final elapsed = await Navigator.of(context).push<Duration>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            FocusTimerScreen(minutes: minutes, planTitle: planTitle),
      ),
    );
    if (elapsed == null || !mounted) return;

    await _handleDidItForCard(
      primaryCard,
      prefillNote: _formatFocusCompletionNote(
        elapsed,
        AppLocalizations.of(context)!,
      ),
    );
  }

  String _formatFocusCompletionNote(Duration elapsed, AppLocalizations l10n) {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds.remainder(60);
    final String duration;
    if (minutes > 0 && seconds > 0) {
      duration = l10n.nowFocusDurationMinSec(minutes, seconds);
    } else if (minutes > 0) {
      duration = l10n.nowFocusDurationMin(minutes);
    } else if (seconds > 0) {
      duration = l10n.nowFocusDurationSec(seconds);
    } else {
      return l10n.nowFocusNoteDoneJustNow;
    }
    return l10n.nowFocusNoteDoneFor(duration);
  }

  /// One record per promise at a time: the photo flow, 사진 없이 했어 and the
  /// notification's 했어 share this guard, so a second tap (even on a card
  /// that is fading out) can't write a second `done`.
  static String _recordKey(String planId) => 'record:$planId';

  /// 사진 없이 했어 (and the notification "did it" action): an optional note,
  /// then the report.
  Future<void> _handleDidItForCard(
    HomeCardModel targetCard, {
    String? dialogTitle,
    String? prefillNote,
  }) async {
    final planId = targetCard.plan?.id;
    if (planId == null) return;

    await _runGuarded(_recordKey(planId), () async {
      final l10n = AppLocalizations.of(context)!;
      final together = TogetherChoice();
      // 1. Show Dialog to input note
      final note = await showDialog<String>(
        context: context,
        builder: (context) => ActionNoteDialog(
          title:
              targetCard.plan?.items.firstOrNull?.title ??
              dialogTitle ??
              l10n.homeDidIt,
          showEmoji: false,
          initialText: prefillNote,
          footer: TogetherToggle(planId: planId, choice: together),
        ),
      );

      if (note == null || !mounted) {
        // Canceled: Do nothing (card didn't vanish)
        return;
      }

      await _completeCard(
        targetCard,
        note: note,
        together: together.selection,
      );
    });
  }

  /// 📸 인증샷 찍기: consent (first time) → camera/album → preview with an
  /// optional note → report with the photo.
  Future<void> _handleProofPhoto() async {
    final card = _activePrimaryCard();
    if (card == null) return;
    await _handleProofPhotoForCard(card);
  }

  Future<void> _handleProofPhotoForCard(HomeCardModel card) async {
    final planId = card.plan?.id;
    if (planId == null) return;

    await _runGuarded(_recordKey(planId), () async {
      final upload = await captureProofPhoto(context, ref);
      if (upload == null || !mounted) return;
      final together = TogetherChoice();
      final note = await showProofPreviewSheet(
        context,
        upload: upload,
        title: card.plan?.items.firstOrNull?.title,
        footer: TogetherToggle(planId: planId, choice: together),
      );
      if (note == null || !mounted) return;
      await _completeCard(
        card,
        note: note,
        photo: upload,
        together: together.selection,
      );
    });
  }

  /// Plays the "done" animation and reports [targetCard], with [photo] when
  /// given. Tells the user when the record was saved without the photo.
  Future<void> _completeCard(
    HomeCardModel targetCard, {
    required String note,
    ProofPhotoUpload? photo,
    TogetherTag? together,
  }) async {
    final planId = targetCard.plan?.id;
    if (planId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    // The cards fade out while the record is saved (an upload can take up to
    // 8 s): no taps on the invisible cards, and a spinner meanwhile.
    _setState(() => _recording = true);

    // Success Animation: Scale Up slightly then Shrink
    await _animationController.animateTo(
      1.05,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    await _animationController.reverse();

    try {
      final result = await ref
          .read(nowTabViewModelProvider.notifier)
          .complete(
            CompletePlanIntent(
              planId,
              message: note,
              photo: photo,
              together: together,
            ),
          );
      // Null result / no action id: nothing was recorded (no state, signed
      // out), so there is no photo outcome to report either.
      if (result == null || result.actionId == null) return;
      if (result.photoFailed) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.proofUploadFailed)));
      } else if (result.queued) {
        // Offline: saved here, reaches the partner once back online.
        messenger.showSnackBar(SnackBar(content: Text(l10n.nowRecordQueued)));
      } else if (result.hasPhoto) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.proofUploadDone)));
      }
    } catch (e) {
      // Error handling (restore animation if failed)
      if (mounted) {
        _animationController.forward();
        messenger.showSnackBar(SnackBar(content: Text(l10n.nowActionFailed)));
      }
    } finally {
      if (mounted) {
        _setState(() => _recording = false);
        // Bring the cards back even when the plan stream didn't emit.
        if (_animationController.status == AnimationStatus.dismissed) {
          _onDataLoaded();
        }
      }
    }
  }

  /// Runs [action] unless the same [key] is already in flight.
  ///
  /// Guards the repeat-tap window between a tap and its network round-trip.
  /// Silently dropping the second tap is the point: these actions are visible to
  /// the partner, so firing twice is worse than doing nothing.
  Future<void> _runGuarded(String key, Future<void> Function() action) async {
    if (!_inFlightActions.add(key)) return;
    try {
      await action();
    } finally {
      _inFlightActions.remove(key);
    }
  }

  Future<void> _handleRest() async {
    final primaryCard = _activePrimaryCard();
    if (primaryCard == null) return;
    await _handleRestForCard(primaryCard);
  }

  Future<void> _handleRestForCard(HomeCardModel primaryCard) async {
    if (primaryCard.plan?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.nowRestPassTitle),
          content: Text(l10n.nowRestPassBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.nowCancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.nowRestPassConfirm,
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _animationController.reverse();
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(RestPlanIntent(primaryCard.plan!.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nowRestPassUsed),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.forward();
        final dl10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is RestPassAlreadyUsedException
                  ? dl10n.nowRestPassAlreadyUsed
                  : dl10n.nowRestPassError,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleRescue(HomeCardModel card) async {
    if (card.plan?.id == null) return;
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(RescuePlanIntent(card.plan!.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nowRescuedSnackbar),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nowRescueFailed),
          ),
        );
      }
    }
  }

  Future<void> _handleSkip() async {
    final primaryCard = _activePrimaryCard();
    if (primaryCard?.plan?.id == null) return;

    final skipped = await _confirmAndSkip(primaryCard!);
    if (skipped && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nowSkippedSnackbar),
        ),
      );
    }
  }

  Future<bool> _skipCard(HomeCardModel targetCard) async {
    if (targetCard.plan?.id == null) return false;

    // 1. Shrink animation (optional, maybe fade out?)
    // For Skip, maybe just standard refresh or specific animation.
    // Let's reuse reverse animation for consistency.
    await _animationController.reverse();

    // 2. Dispatch Intent
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(SkipPlanIntent(targetCard.plan!.id!));
      return true;
    } catch (e) {
      if (mounted) _animationController.forward();
      return false;
    }
  }

  /// 카드 우측 상단 '넘기기' → 잠시 후에 할지 / 오늘은 안 할지 고르는 시트.
  Future<void> _showActionDeferSheet(HomeCardModel card) async {
    if (card.plan?.id == null) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.schedule_rounded, color: AppColors.primary),
                title: Text(l10n.nowDeferLaterTitle),
                subtitle: Text(l10n.nowDeferLaterSubtitle),
                onTap: () => Navigator.pop(ctx, 'later'),
              ),
              // The streak-safe way out first, when there is one.
              if (card.plan?.canUseRestToday == true)
                ListTile(
                  key: const ValueKey('defer-rest'),
                  leading: Icon(Icons.spa_outlined, color: AppColors.primary),
                  title: Text(l10n.nowRestToday),
                  subtitle: Text(l10n.nowDeferRestSubtitle),
                  onTap: () => Navigator.pop(ctx, 'rest'),
                ),
              ListTile(
                key: const ValueKey('defer-skip'),
                leading: Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.textSecondary,
                ),
                title: Text(l10n.nowSkipTodayTitle),
                subtitle: Text(l10n.nowSkipTodaySubtitle),
                onTap: () => Navigator.pop(ctx, 'skip'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (choice == 'later') {
      await _handleDeferLater(card);
    } else if (choice == 'rest') {
      await _handleRestForCard(card);
    } else if (choice == 'skip') {
      final ok = await _confirmAndSkip(card);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nowSkipTodayDone),
          ),
        );
      }
    }
  }

  /// '잠시 후에 할게' — 다음 실천으로 넘기고, 잠시 후 다시 알림을 예약한다.
  Future<void> _handleDeferLater(HomeCardModel card) async {
    await _scheduleDeferReminder(card);

    // 오늘의 실천 카드가 여러 개면 다음 카드로 넘긴다.
    final state = ref.read(nowTabViewModelProvider).value;
    final count = state?.primaryCarouselCards.length ?? 0;
    if (count > 1) {
      final next = (_primaryActiveIndex + 1).clamp(0, count - 1);
      if (next != _primaryActiveIndex) {
        _setState(() {
          _primaryActiveIndex = next;
          _animateCarouselEntrance = false;
        });
        _animationController.forward(from: 0.0);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.nowDeferLaterDone),
        ),
      );
    }
  }

  Future<void> _scheduleDeferReminder(HomeCardModel card) async {
    final plan = card.plan;
    if (plan?.id == null) return;
    final l10n = AppLocalizations.of(context)!;
    final itemTitle = plan!.items.firstOrNull?.title;
    final when = DateTime.now().add(const Duration(hours: 1));
    // 플랜 알림/스누즈 id 영역과 겹치지 않는 범위에서 안정적 id 생성.
    final id = 1800000000 + (plan.id!.hashCode.abs() % 1000000);
    try {
      await local_notifications.NotificationService().scheduleNotificationAt(
        id: id,
        title: l10n.nowDeferReminderTitle,
        body: (itemTitle != null && itemTitle.isNotEmpty)
            ? itemTitle
            : l10n.nowDeferReminderBody,
        scheduledDate: when,
        planId: plan.id,
        opensInput: true,
      );
    } catch (e) {
      // 알림 예약 실패는 치명적이지 않다(권한 거부 등) — 넘기기 자체는 진행.
      debugPrint('[NowTab] scheduleDeferReminder failed (ignored): $e');
    }
  }

  void _handleCreatePlan() {
    // 계획 생성 플로우 진입
    context.push(AppRoutes.planCreate);
  }

  void _handleModify(HomeCardModel card) {
    // 계획 수정 (반려된 계획 재수정)
    if (card.plan != null) {
      context.push(AppRoutes.planCreate, extra: card.plan);
    }
  }
}
