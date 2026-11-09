part of '../now_tab_screen.dart';

/// Actions between partners on the 지금 tab: approve / reject, knocks and
/// replies, cheers and reactions, promises and the 4-week settlement.
/// Split out of now_tab_screen.dart.
extension _NowTabPartnerActions on _NowTabState {
  Future<void> _handleApprove(HomeCardModel managerCard) async {
    final planId = managerCard.plan?.id;
    if (planId == null) return;

    await _runGuarded('approve:$planId', () async {
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(ApprovePlanIntent(planId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowApproveCheering),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowApproveFailed),
            ),
          );
        }
      }
    });
  }

  Future<void> _handleReject(HomeCardModel managerCard) async {
    if (managerCard.plan?.id == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final dl10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(dl10n.nowRejectDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRejectOption(context, dl10n.nowRejectLessFrequent),
              const SizedBox(height: 8),
              _buildRejectOption(context, dl10n.nowRejectDifferentTime),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  Navigator.pop(context, 'custom');
                },
                style: _rejectOptionStyle(),
                child: Text(dl10n.nowRejectCustom),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                dl10n.nowCancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    String? finalReason = reason;
    if (reason == 'custom') {
      if (!mounted) return;
      finalReason = await _showCustomRejectInput(context);
    }

    if (finalReason != null && finalReason.isNotEmpty) {
      if (!mounted) return;
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(
              RejectPlanIntent(managerCard.plan!.id!, reason: finalReason),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowRejectRequested),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowActionFailed),
            ),
          );
        }
      }
    }
  }

  Future<String?> _showCustomRejectInput(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.nowRejectCustomDialogTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.nowRejectCustomHint,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.nowCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.nowSend),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRejectOption(BuildContext context, String text) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context, text),
      style: _rejectOptionStyle(),
      child: Text(text),
    );
  }

  ButtonStyle _rejectOptionStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _handleCardTap(HomeCardModel model) {
    if (model.plan != null) {
      context.pushNamed('plan-detail', extra: model.plan);
    }
  }

  Future<void> _handlePokeUser(HomeCardModel model) async {
    if (model.partnerUid == null) return;
    final l10n = AppLocalizations.of(context)!;
    await _runGuarded('pokeUser:${model.partnerUid}', () async {
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(
              PokeUserIntent(
                model.partnerUid!,
                message: l10n.nowPokeNoActivityMessage,
              ),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.nowPokeSent)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowPokeFailed),
            ),
          );
        }
      }
    });
  }

  Future<void> _handlePokePartner(HomeCardModel model) async {
    if (model.plan?.id == null) return;
    final l10n = AppLocalizations.of(context)!;
    await _runGuarded('pokePartner:${model.plan!.id}', () async {
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(
              PokePartnerIntent(
                model.plan!.id!,
                message: l10n.nowPokeAgainMessage,
              ),
            );
        if (mounted) {
          _setState(() => _knockedPlans.add(_todayKeyFor(model.plan!.id!)));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowPokeAgainSent),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowPokeFailed),
            ),
          );
        }
      }
    });
  }

  /// 응원 보내기 on the partner's missed-workout card: a cheers doc only — not
  /// 인정, so their unrecorded day is never marked acknowledged.
  Future<void> _handleSendCheer(HomeCardModel card) async {
    final planId = card.plan?.id;
    final toUserId = card.partnerUid ?? card.plan?.userId;
    if (planId == null || toUserId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    await _runGuarded('cheer:$planId', () async {
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(
              SendCheerIntent(
                toUserId,
                planId: planId,
                emoji: '💪',
                message: l10n.nowCheerDefaultMessage,
              ),
            );
        if (mounted) _setState(() => _cheeredPlans.add(_todayKeyFor(planId)));
        messenger.showSnackBar(SnackBar(content: Text(l10n.nowCheerSent)));
      } catch (_) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.nowCheerFailed)));
      }
    });
  }

  /// 지금 간다 🏃 / 오늘은 봐줘 🙏 to the partner who knocked today.
  Future<void> _handlePokeReply(HomeCardModel card, PokeReplyKind kind) async {
    final planId = card.plan?.id;
    final toUserId = card.plan?.managerId;
    if (planId == null || toUserId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final store = ref.read(pokeReplyStoreProvider);
    await _runGuarded('pokeReply:$planId', () async {
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(
              ReplyToPokeIntent(
                planId,
                toUserId: toUserId,
                kind: kind,
                message: kind == PokeReplyKind.coming
                    ? l10n.nowPokeReplyComing
                    : l10n.nowPokeReplyPass,
              ),
            );
        await store.markReplied(planId, DateTime.now());
        if (mounted) _setState(() {});
        messenger.showSnackBar(SnackBar(content: Text(l10n.nowPokeReplySent)));
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.nowPokeReplyFailed)),
        );
      }
    });
  }

  /// The replies to today's knock for [card], or null when they don't apply.
  ValueChanged<PokeReplyKind>? _pokeReplyFor(HomeCardModel card) {
    final plan = card.plan;
    final now = DateTime.now();
    if (!showsPokeReplies(plan, now: now)) return null;
    if (ref.watch(pokeReplyStoreProvider).hasReplied(plan!.id!, now)) {
      return null;
    }
    return (kind) => _handlePokeReply(card, kind);
  }

  Future<void> _handleAcknowledgePromiseSettled(HomeCardModel card) async {
    if (card.plan?.id == null) return;
    final l10n = AppLocalizations.of(context)!;

    final comment = await showDialog<String>(
      context: context,
      builder: (context) => ActionNoteDialog(
        title: l10n.nowPromiseAckDialogTitle,
        hintText: l10n.nowPromiseAckDialogHint,
        buttonLabel: l10n.nowPromiseAckDialogConfirm,
        showEmoji: false,
      ),
    );

    // Cancelled
    if (comment == null) return;

    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            AcknowledgePromiseSettlementIntent(
              card.plan!.id!,
              comment: comment.trim().isEmpty ? null : comment.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.nowPromiseAckSnackbar)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.nowPromiseAckFailed)));
      }
    }
  }

  Future<void> _handleContinueAfterSettlement(HomeCardModel card) async {
    if (card.plan?.id == null) return;

    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            RecordPilotSettlementIntent(
              card.plan!.id!,
              nextPlanIntent: 'continue',
            ),
          );
    } catch (_) {
      // Don't move on to the next plan if the settlement wasn't recorded.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nowActionFailed),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    context.push(AppRoutes.planCreate, extra: card.plan!.asRestartTemplate());
  }

  Future<void> _handleExitAfterSettlement(HomeCardModel card) async {
    if (card.plan?.id == null) return;

    final reason = await _showPilotExitReasonDialog(context);
    if (reason == null || reason.trim().isEmpty) return;

    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            RecordPilotSettlementIntent(
              card.plan!.id!,
              nextPlanIntent: 'stop',
              exitReason: reason,
            ),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nowActionFailed),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.nowSettlementSaved)),
    );
  }

  Future<String?> _showPilotExitReasonDialog(BuildContext context) {
    final customController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.nowExitDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExitReasonOption(context, l10n.nowExitReasonWeakPoke),
              const SizedBox(height: 8),
              _buildExitReasonOption(context, l10n.nowExitReasonTooBig),
              const SizedBox(height: 8),
              _buildExitReasonOption(context, l10n.nowExitReasonPartnerBurden),
              const SizedBox(height: 12),
              TextField(
                controller: customController,
                decoration: InputDecoration(
                  labelText: l10n.nowExitReasonCustomLabel,
                  hintText: l10n.nowExitReasonCustomHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.nowCancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                customController.text.trim().isEmpty
                    ? l10n.nowExitReasonNoCustom
                    : customController.text.trim(),
              ),
              child: Text(
                l10n.nowExitSubmit,
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    ).whenComplete(customController.dispose);
  }

  Widget _buildExitReasonOption(BuildContext context, String reason) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context, reason),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.divider),
        alignment: Alignment.centerLeft,
      ),
      child: Text(reason),
    );
  }

  void _maybeAutoAcknowledgePoke(HomeCardModel? card) {
    if (card == null || card.state != HomeCardState.poked) return;
    final planId = card.plan?.id;
    if (planId == null) return;
    if (!_autoAcknowledgedPokes.add(planId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Automatic and invisible to the user, so there is nothing to report — but
      // it still has to be caught, or a failure becomes an unhandled async error.
      // Drop the id again so a later rebuild can retry the acknowledgement.
      unawaited(
        ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(AcknowledgePokeIntent(planId))
            .catchError((Object _) {
              _autoAcknowledgedPokes.remove(planId);
            }),
      );
    });
  }

  Future<void> _handleRespondPromise(HomeCardModel card, bool accept) async {
    if (card.plan?.id == null) return;
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(RespondPromiseIntent(card.plan!.id!, accept: accept));
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? l10n.nowPromiseAccepted : l10n.nowPromiseDeclined,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.nowPromiseResponseFailed,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleProposePromise(HomeCardModel card) async {
    final plan = card.plan;
    if (plan?.id == null) return;

    final result =
        await showModalBottomSheet<
          ({PromiseReward? reward, PromisePenalty? penalty})
        >(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              SafeArea(top: false, child: PromiseProposalSheet(plan: plan!)),
        );

    if (result == null) return;
    if (result.reward == null && result.penalty == null) return;

    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            ProposePromiseIntent(
              card.plan!.id!,
              reward: result.reward,
              penalty: result.penalty,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.nowPromiseProposed),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.nowPromiseProposeFailed,
            ),
          ),
        );
      }
    }
  }

  /// One-tap 인정 on a partner card: verifies today's record and sends
  /// [emoji] — no dialog, no keyboard.
  Future<void> _handleReact(HomeCardModel card, String emoji) async {
    final plan = card.plan;
    final planId = plan?.id;
    if (plan == null || planId == null) return;
    await _runGuarded('react:$planId', () async {
      await _sendReaction(card, emoji, surface: 'now');
    });
  }

  /// "한마디": the optional note dialog, sent as 인정 with ❤️.
  Future<void> _handleReactWithNote(HomeCardModel card) async {
    final planId = card.plan?.id;
    if (planId == null) return;

    final l10n = AppLocalizations.of(context)!;
    final feedback = await showDialog<String>(
      context: context,
      builder: (context) => ActionNoteDialog(
        title:
            card.plan?.items.firstOrNull?.title ??
            l10n.nowPartnerActionFallback,
        hintText: l10n.nowActionNoteHint,
        buttonLabel: l10n.nowVerifyAndSend,
        showEmoji: false,
      ),
    );
    if (feedback == null || !mounted) return;

    await _runGuarded('react:$planId', () async {
      await _sendReaction(
        card,
        kProofReactions.first,
        message: feedback.trim().isEmpty ? null : feedback.trim(),
        surface: 'now_note',
      );
    });
  }

  Future<void> _sendReaction(
    HomeCardModel card,
    String emoji, {
    String? message,
    required String surface,
  }) async {
    final plan = card.plan!;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            CheerPartnerActionIntent(plan.id!, emoji, message: message),
          );
      logPartnerReacted(
        reportedAt: plan.lastProofAt ?? _lastActionNoteDate(plan),
        surface: surface,
        reaction: emoji,
        hasPhoto: todayProofPhotoPathOf(plan) != null,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.nowReactedSnackbar(emoji)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.nowCheerFailed)));
    }
  }
}
