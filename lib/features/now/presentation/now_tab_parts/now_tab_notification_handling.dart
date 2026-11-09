part of '../now_tab_screen.dart';

/// Opened notifications on the 지금 tab: the queued 했어 / skip requests, the
/// focus on a notification's card, its quick actions and the check-in sheet.
/// Split out of now_tab_screen.dart.
extension _NowTabNotificationHandling on _NowTabState {
  void _queueNotificationInput(
    local_notifications.NotificationInputRequest request,
  ) {
    if (!mounted) return;

    _pendingNotificationInput = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingNotificationInputIfReady();
    });
  }

  void _openPendingNotificationInputIfReady() {
    if (!mounted ||
        _isHandlingNotificationInput ||
        _isHandlingNotificationSkip) {
      return;
    }

    final request = _pendingNotificationInput;
    if (request == null) return;

    final nowState = ref.read(nowTabViewModelProvider).value;
    if (nowState == null) return;

    final targetCard = _findNotificationTargetCard(
      nowState,
      planId: request.planId,
    );
    if (targetCard == null) return;

    _pendingNotificationInput = null;
    _isHandlingNotificationInput = true;
    unawaited(
      _handleDidItForCard(targetCard, dialogTitle: request.title).whenComplete(
        () {
          _isHandlingNotificationInput = false;
          if (_pendingNotificationInput != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openPendingNotificationInputIfReady();
            });
          }
          if (_pendingNotificationSkip != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openPendingNotificationSkipIfReady();
            });
          }
        },
      ),
    );
  }

  void _queueNotificationSkip(
    local_notifications.NotificationSkipRequest request,
  ) {
    if (!mounted) return;

    _pendingNotificationSkip = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingNotificationSkipIfReady();
    });
  }

  void _openPendingNotificationSkipIfReady() {
    if (!mounted ||
        _isHandlingNotificationInput ||
        _isHandlingNotificationSkip) {
      return;
    }

    final request = _pendingNotificationSkip;
    if (request == null) return;

    final nowState = ref.read(nowTabViewModelProvider).value;
    if (nowState == null) return;

    final targetCard = _findNotificationTargetCard(
      nowState,
      planId: request.planId,
    );
    if (targetCard == null) return;

    _pendingNotificationSkip = null;
    _isHandlingNotificationSkip = true;
    unawaited(
      _confirmAndSkipFromNotification(
        targetCard,
        dialogTitle: request.title,
      ).whenComplete(() {
        _isHandlingNotificationSkip = false;
        if (_pendingNotificationSkip != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openPendingNotificationSkipIfReady();
          });
        }
        if (_pendingNotificationInput != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openPendingNotificationInputIfReady();
          });
        }
      }),
    );
  }

  HomeCardModel? _findNotificationTargetCard(
    NowTabState state, {
    String? planId,
  }) {
    if (planId != null && planId.isNotEmpty) {
      for (final card in state.allCards) {
        if (card.plan?.id == planId && _canOpenInputFromNotification(card)) {
          return card;
        }
      }
      return null;
    }

    final primaryCard = state.primaryCard;
    if (primaryCard != null && _canOpenInputFromNotification(primaryCard)) {
      return primaryCard;
    }

    for (final card in state.allCards) {
      if (_canOpenInputFromNotification(card)) {
        return card;
      }
    }

    return null;
  }

  bool _canOpenInputFromNotification(HomeCardModel card) {
    if (card.plan?.id == null) return false;

    return card.state == HomeCardState.nowAction ||
        card.state == HomeCardState.overdue ||
        card.state == HomeCardState.poked;
  }

  Future<void> _confirmAndSkipFromNotification(
    HomeCardModel targetCard, {
    String? dialogTitle,
  }) async {
    final skipped = await _confirmAndSkip(targetCard, dialogTitle: dialogTitle);
    if (!skipped || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.nowSkippedSnackbar)),
    );
  }

  /// 오늘은 패스: a skip counts as a missed day (the 둘운완 streak can reset)
  /// and the partner is told, so every path asks first. Returns whether the
  /// day was skipped.
  Future<bool> _confirmAndSkip(
    HomeCardModel targetCard, {
    String? dialogTitle,
  }) async {
    if (targetCard.plan?.id == null) return false;

    final l10n = AppLocalizations.of(context)!;
    final planTitle =
        targetCard.plan?.items.firstOrNull?.title ??
        dialogTitle ??
        l10n.nowTodayPromiseFallback;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dl10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(dl10n.nowSkipDialogTitle),
          content: Text(dl10n.nowSkipDialogBody(planTitle)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                dl10n.nowCancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                dl10n.nowSkipToday,
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return false;

    return _skipCard(targetCard);
  }

  void _queueFocus(NotificationFocusRequest request) {
    if (!mounted) return;
    _dropPendingFocus();
    _pendingFocus = request;
    // Consumed here; cleared outside the listener that delivered it.
    Future.microtask(() {
      if (mounted) ref.read(nowFocusRequestProvider.notifier).clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingFocusIfReady();
    });
  }

  /// An opened notification: brings its promise's card into view. A
  /// reminder / knock also offers the same choices as the hero (📸 인증샷
  /// 찍기 first) — the tap used to open a note-only dialog that recorded
  /// without a photo. A promise that isn't on today's cards is looked for on
  /// the 기록 tab.
  void _openPendingFocusIfReady() {
    if (!mounted ||
        _isHandlingCheckIn ||
        _isHandlingNotificationInput ||
        _isHandlingNotificationSkip) {
      return;
    }
    final request = _pendingFocus;
    if (request == null) return;
    final now = DateTime.now();
    // A card that never shows up is not waited for: no jump or sheet popping
    // up minutes later.
    if (request.isExpired(now)) {
      _dropPendingFocus();
      return;
    }
    final nowState = ref.read(nowTabViewModelProvider).value;
    if (nowState == null) return;
    final planId = request.planId;

    // A push's button: run it on the promise's card, like the card's own
    // button. A card that isn't there (or doesn't fit) is just shown below.
    final quickAction = request.quickAction;
    if (quickAction != null && planId != null) {
      final spot = locateNowCard(nowState, planId);
      final card = spot == null ? null : nowCardAt(nowState, spot);
      if (spot != null &&
          card?.plan?.id == planId &&
          quickActionFitsArea(quickAction, spot.area) &&
          _quickActionApplies(card!, quickAction)) {
        _dropPendingFocus();
        _focusSpot(nowState, spot);
        unawaited(_runQuickAction(card, quickAction));
        return;
      }
    }

    if (request.checkIn && quickAction == null) {
      final card = _findCheckInCard(nowState, planId: planId);
      if (card != null) {
        _dropPendingFocus();
        final spot = locateNowCard(nowState, card.plan!.id!);
        if (spot != null) _focusSpot(nowState, spot);
        _isHandlingCheckIn = true;
        unawaited(
          _showCheckInSheet(
            card,
          ).whenComplete(() => _isHandlingCheckIn = false),
        );
        return;
      }
    }

    // Already recorded (no check-in to offer) or not a check-in: just show
    // the card.
    final spot = planId == null ? null : locateNowCard(nowState, planId);
    if (spot != null) {
      _dropPendingFocus();
      _focusSpot(nowState, spot);
      return;
    }

    // Not on the cards (yet): the first snapshot can come from the cache, so
    // give the server's a moment before looking elsewhere.
    if (!_pendingFocusGraceOver) {
      _pendingFocusGrace ??= Timer(notificationFocusGrace, () {
        _pendingFocusGraceOver = true;
        _openPendingFocusIfReady();
      });
      return;
    }
    _dropPendingFocus();
    if (planId != null) {
      // Not today's (an earlier day's record, an ended promise): on 기록.
      ref
          .read(historyFocusRequestProvider.notifier)
          .request(planId, actionId: request.actionId, day: request.day);
    }
  }

  /// Whether the card still offers [action]'s button: the push may be
  /// answered late (already 인정, already replied, no longer missed).
  bool _quickActionApplies(HomeCardModel card, NotificationQuickAction action) {
    final plan = card.plan;
    if (plan?.id == null) return false;
    final now = DateTime.now();
    return switch (action) {
      NotificationQuickAction.props =>
        card.state == HomeCardState.partnerAction ||
            card.state == HomeCardState.partnerTodayComplete,
      NotificationQuickAction.cheer =>
        leadsWithCheer(card.state, hasMissedNotice: card.hasMissedNotice) &&
            !_cheeredPlans.contains(_todayKeyFor(plan!.id!)),
      NotificationQuickAction.pokeComing || NotificationQuickAction.pokePass =>
        showsPokeReplies(plan, now: now) &&
            !ref.read(pokeReplyStoreProvider).hasReplied(plan!.id!, now),
      // 나도 했어 is answered by the home screen, not on a card.
      NotificationQuickAction.togetherDone => false,
    };
  }

  Future<void> _runQuickAction(
    HomeCardModel card,
    NotificationQuickAction action,
  ) async {
    final planId = card.plan!.id!;
    switch (action) {
      case NotificationQuickAction.props:
        await _runGuarded('react:$planId', () async {
          await _sendReaction(
            card,
            kProofReactions.first,
            surface: 'notification',
          );
        });
      case NotificationQuickAction.pokeComing:
        await _handlePokeReply(card, PokeReplyKind.coming);
      case NotificationQuickAction.pokePass:
        await _handlePokeReply(card, PokeReplyKind.pass);
      case NotificationQuickAction.cheer:
        await _handleSendCheer(card);
      case NotificationQuickAction.togetherDone:
        break;
    }
  }

  void _dropPendingFocus() {
    _pendingFocus = null;
    _pendingFocusGrace?.cancel();
    _pendingFocusGrace = null;
    _pendingFocusGraceOver = false;
  }

  /// Brings the card at [spot] up: the carousel turns to it, and the card
  /// scrolls into view with a short outline.
  void _focusSpot(NowTabState state, NowCardSpot spot) {
    if (spot.area == NowCardArea.carousel) {
      final carousel = state.primaryCarouselCards;
      // Known now, so the next snapshot of the same cards doesn't turn the
      // carousel back to the first one.
      _carouselSignature = _carouselSignatureFor(carousel);
      _goToCarouselIndex(spot.index, carousel.length);
    }
    _setState(() {
      _focusedSpot = spot;
      _focusToken++;
    });
    // Taken in by the frame on this build; a card that moves into that slot
    // later must not be focused.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setState(() => _focusedSpot = null);
    });
  }

  /// The [NotificationFocusFrame] token of the card at [area] / [index].
  int? _focusTokenFor(NowCardArea area, [int index = 0]) {
    final spot = _focusedSpot;
    if (spot == null) return null;
    final matches = switch (area) {
      // One slot shows the carousel's active card (or the lone primary).
      NowCardArea.carousel || NowCardArea.primary =>
        spot.area == NowCardArea.carousel || spot.area == NowCardArea.primary,
      _ => spot.area == area && spot.index == index,
    };
    return matches ? _focusToken : null;
  }

  HomeCardModel? _findCheckInCard(NowTabState state, {String? planId}) {
    final now = DateTime.now();
    bool asks(HomeCardModel card) =>
        showsTodayCheckInHero(card.state, card.plan, now: now);
    if (planId != null && planId.isNotEmpty) {
      for (final card in state.allCards) {
        if (card.plan?.id == planId && asks(card)) return card;
      }
      return null;
    }
    final primary = state.primaryCard;
    if (primary != null && asks(primary)) return primary;
    for (final card in state.allCards) {
      if (asks(card)) return card;
    }
    return null;
  }

  /// 📸 인증샷 찍기 / 사진 없이 했어 / 오늘은 쉴게 (or 오늘은 패스할게) for [card].
  Future<void> _showCheckInSheet(HomeCardModel card) async {
    final plan = card.plan;
    if (plan?.id == null) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final legacy = workoutDisplayFor(l10n, plan!.workoutType) == null;
        final canRest = plan.canUseRestToday;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
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
                const SizedBox(height: 16),
                Text(
                  todayCheckInQuestion(l10n, plan),
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const ValueKey('check-in-sheet-photo'),
                  onPressed: () => Navigator.pop(ctx, 'photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    legacy ? l10n.nowHeroVerifyLegacy : l10n.nowProofTakePhoto,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('check-in-sheet-no-photo'),
                  onPressed: () => Navigator.pop(ctx, 'done'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.nowDidItNoPhoto,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  key: ValueKey(
                    canRest ? 'check-in-sheet-rest' : 'check-in-sheet-skip',
                  ),
                  onPressed: () => Navigator.pop(ctx, canRest ? 'rest' : 'skip'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(
                    canRest ? l10n.nowRestToday : l10n.nowActionSkipToday,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'photo':
        await _handleProofPhotoForCard(card);
      case 'done':
        await _handleDidItForCard(card);
      case 'rest':
        await _handleRestForCard(card);
      case 'skip':
        final skipped = await _confirmAndSkip(card);
        if (skipped && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowSkippedSnackbar),
            ),
          );
        }
    }
  }
}
