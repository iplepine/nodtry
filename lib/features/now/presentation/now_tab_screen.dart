import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../models/plan_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_underlined_text.dart';
import '../../../widgets/quiet_header.dart';
import '../../../widgets/centered_emoji.dart';
import '../../../widgets/time_chip.dart';
import '../../../models/home_state.dart';
import '../../../routes/app_router.dart';
import '../../../utils/time_formatter.dart';
import '../../../utils/build_flags.dart';
import '../../../models/promise_model.dart';
import 'now_tab_intent.dart';
import 'now_tab_state.dart';
import 'now_tab_viewmodel.dart';
import 'now_tab_fake_states.dart';
import '../../../widgets/action_note_dialog.dart';
import '../../../services/notification_service.dart' as local_notifications;
import 'focus_timer/focus_timer_picker.dart';
import 'focus_timer/focus_timer_screen.dart';
import 'promise/active_promise_chip.dart';

/// 지금 탭 - Now Card 기반 관계 중심 홈
class NowTab extends ConsumerStatefulWidget {
  const NowTab({super.key});

  @override
  ConsumerState<NowTab> createState() => _NowTabState();
}

class _NowTabState extends ConsumerState<NowTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _primaryFadeAnimation;
  late Animation<double> _primaryScaleAnimation;
  late Animation<double> _secondaryFadeAnimation;
  late Animation<double> _managerFadeAnimation;
  StreamSubscription<local_notifications.NotificationInputRequest>?
  _notificationInputSubscription;
  StreamSubscription<local_notifications.NotificationSkipRequest>?
  _notificationSkipSubscription;
  local_notifications.NotificationInputRequest? _pendingNotificationInput;
  local_notifications.NotificationSkipRequest? _pendingNotificationSkip;
  bool _isHandlingNotificationInput = false;
  bool _isHandlingNotificationSkip = false;
  final Set<String> _autoAcknowledgedPokes = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Primary Card 애니메이션: Fade + Scale
    _primaryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _primaryScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Secondary Card 애니메이션: Fade
    _secondaryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Manager Card 애니메이션: Fade
    _managerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    final notificationService = local_notifications.NotificationService();
    _notificationInputSubscription = notificationService.inputRequests.listen(
      _queueNotificationInput,
    );
    _notificationSkipSubscription = notificationService.skipRequests.listen(
      _queueNotificationSkip,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingRequest = notificationService.takePendingInputRequest();
      if (pendingRequest != null) {
        _queueNotificationInput(pendingRequest);
      }

      final pendingSkipRequest = notificationService.takePendingSkipRequest();
      if (pendingSkipRequest != null) {
        _queueNotificationSkip(pendingSkipRequest);
      }
    });
  }

  @override
  void dispose() {
    _notificationInputSubscription?.cancel();
    _notificationSkipSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // 데이터 변경 감지 시 애니메이션 처리
  void _onDataLoaded() {
    if (mounted) {
      _animationController.forward(from: 0.0);
    }
  }

  Future<void> _handleDidIt() async {
    final primaryCard = ref.read(nowTabViewModelProvider).value?.primaryCard;
    if (primaryCard == null) return;
    await _handleDidItForCard(primaryCard);
  }

  Future<void> _handleFocusTimer() async {
    final primaryCard = ref.read(nowTabViewModelProvider).value?.primaryCard;
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
        builder: (_) => FocusTimerScreen(
          minutes: minutes,
          planTitle: planTitle,
        ),
      ),
    );
    if (elapsed == null || !mounted) return;

    await _handleDidItForCard(
      primaryCard,
      prefillNote: _formatFocusCompletionNote(elapsed, AppLocalizations.of(context)!),
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

  Future<void> _handleDidItForCard(
    HomeCardModel targetCard, {
    String? dialogTitle,
    String? prefillNote,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (targetCard.plan?.id == null) return;

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
      ),
    );

    if (note == null) {
      // Canceled: Do nothing (card didn't vanish)
      return;
    }

    // 2. Success Animation: Scale Up slightly then Shrink
    // First, animate scale up to 1.1 quickly
    await _animationController.animateTo(
      1.05,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );

    // Then reverse (shrink)
    await _animationController.reverse();

    // 3. Dispatch Intent with note
    try {
      final planId = targetCard.plan?.id;
      if (planId != null) {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(CompletePlanIntent(planId, message: note));
      }
    } catch (e) {
      // Error handling (restore animation if failed)
      if (mounted) _animationController.forward();
    }
  }

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
    if (targetCard.plan?.id == null) return;

    final l10n = AppLocalizations.of(context)!;
    final planTitle =
        targetCard.plan?.items.firstOrNull?.title ?? dialogTitle ?? l10n.nowTodayPromiseFallback;
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
              child: Text(dl10n.nowCancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(dl10n.nowSkipToday, style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final skipped = await _skipCard(targetCard);
    if (!skipped || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowSkippedSnackbar)));
  }

  Future<void> _handleCheckIt(HomeCardModel managerCard) async {
    if (managerCard.plan?.id == null) return;

    final planId = managerCard.plan!.id!;

    // 카드 상태에 따라 다른 인텐트 발송
    if (managerCard.state == HomeCardState.partnerPlanCreate ||
        managerCard.state == HomeCardState.partnerPlanModify) {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowApproveFailed)));
        }
      }
    } else if (managerCard.state == HomeCardState.partnerAction ||
        managerCard.state == HomeCardState.partnerTodayComplete) {
      // 실천 확인
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(VerifyPartnerPlanIntent(planId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.nowVerifyDone),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowVerifyFailed)));
        }
      }
    } else {
      // Fallback
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(CheckPartnerActionIntent(planId));
    }
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
              child: Text(dl10n.nowCancel, style: TextStyle(color: AppColors.textSecondary)),
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
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            RejectPlanIntent(managerCard.plan!.id!, reason: finalReason),
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowRejectRequested)));
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

  Future<void> _handleCheer(HomeCardModel managerCard) async {
    if (managerCard.plan?.id == null) return;

    final l10n = AppLocalizations.of(context)!;
    // 1. Random Reaction Selection
    final reactions = [
      ('🔥', l10n.nowCheerExcited),
      ('❤️', l10n.nowCheerLove),
      ('👍', l10n.nowCheerProud),
      ('💪', l10n.nowCheerStrength),
    ];
    final random = Random();
    final selected = reactions[random.nextInt(reactions.length)];
    final reactionType = selected.$1;
    final reactionMessage = selected.$2;

    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            CheerPartnerActionIntent(managerCard.plan!.id!, reactionType),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reactionMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowCheerFailed)));
      }
    }
  }

  void _handleCardTap(HomeCardModel model) {
    if (model.plan != null) {
      context.pushNamed('plan-detail', extra: model.plan);
    }
  }

  Future<void> _handlePass(HomeCardModel managerCard) async {
    if (managerCard.plan?.id == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.nowActionPass)),
      );
    }

    // Dispatch Pass Intent
    await ref
        .read(nowTabViewModelProvider.notifier)
        .dispatch(PassPlanIntent(managerCard.plan!.id!));
  }

  Future<void> _handlePokeUser(HomeCardModel model) async {
    if (model.partnerUid == null) return;
    final l10n = AppLocalizations.of(context)!;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowPokeSent)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowPokeFailed)));
      }
    }
  }

  Future<void> _handlePokePartner(HomeCardModel model) async {
    if (model.plan?.id == null) return;
    final l10n = AppLocalizations.of(context)!;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowPokeAgainSent)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowPokeFailed)));
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.nowPromiseAckSnackbar)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.nowPromiseAckFailed)),
        );
      }
    }
  }

  Future<void> _handleContinueAfterSettlement(HomeCardModel card) async {
    if (card.plan?.id == null) return;

    await ref
        .read(nowTabViewModelProvider.notifier)
        .dispatch(
          RecordPilotSettlementIntent(
            card.plan!.id!,
            nextPlanIntent: 'continue',
          ),
        );

    if (!mounted) return;
    context.push(AppRoutes.planCreate, extra: _planAsNewTemplate(card.plan!));
  }

  Plan _planAsNewTemplate(Plan plan) {
    return Plan(
      userId: plan.userId,
      managerId: plan.managerId,
      startDate: plan.startDate,
      endDate: plan.endDate,
      state: plan.state,
      items: plan.items,
      createdAt: plan.createdAt,
      completedDates: plan.completedDates,
      skippedDates: plan.skippedDates,
      verifiedDates: plan.verifiedDates,
      rescuedDates: plan.rescuedDates,
      restedDates: plan.restedDates,
      lastActionNote: plan.lastActionNote,
      lastComment: plan.lastComment,
    );
  }

  Future<void> _handleExitAfterSettlement(HomeCardModel card) async {
    if (card.plan?.id == null) return;

    final reason = await _showPilotExitReasonDialog(context);
    if (reason == null || reason.trim().isEmpty) return;

    await ref
        .read(nowTabViewModelProvider.notifier)
        .dispatch(
          RecordPilotSettlementIntent(
            card.plan!.id!,
            nextPlanIntent: 'stop',
            exitReason: reason,
          ),
        );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowSettlementSaved)));
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
              child: Text(l10n.nowExitSubmit, style: TextStyle(color: AppColors.primary)),
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

  Future<void> _handleRest() async {
    final primaryCard = ref.read(nowTabViewModelProvider).value?.primaryCard;
    if (primaryCard?.plan?.id == null) return;

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
              child: Text(l10n.nowCancel, style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.nowRestPassConfirm, style: TextStyle(color: AppColors.primary)),
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
          .dispatch(RestPlanIntent(primaryCard!.plan!.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nowRestPassUsed)),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.forward();
        final dl10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('이미 사용') || e.toString().contains('already used')
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
          SnackBar(content: Text(AppLocalizations.of(context)!.nowRescuedSnackbar)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowRescueFailed)));
      }
    }
  }

  Future<void> _handleSkip() async {
    final primaryCard = ref.read(nowTabViewModelProvider).value?.primaryCard;
    if (primaryCard?.plan?.id == null) return;

    await _skipCard(primaryCard!);
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

  void _maybeAutoAcknowledgePoke(HomeCardModel? card) {
    if (card == null || card.state != HomeCardState.poked) return;
    final planId = card.plan?.id;
    if (planId == null) return;
    if (!_autoAcknowledgedPokes.add(planId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(AcknowledgePokeIntent(planId));
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
          SnackBar(content: Text(accept ? l10n.nowPromiseAccepted : l10n.nowPromiseDeclined)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowPromiseResponseFailed)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowPromiseProposed)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowPromiseProposeFailed)));
      }
    }
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
      return '${AppLocalizations.of(context)!.pastUncompletedTimeChip} · ${AppLocalizations.of(context)!.timeChipPassed}';
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
    return null;
  }

  /// Time Chip 타입 가져오기
  TimeChipType? _getTimeChipType(HomeCardModel model) {
    if (model.state == HomeCardState.overdue) {
      return TimeChipType.past;
    }

    final text = _getTimeChipText(model);
    if (text == null) return null;

    final l10n = AppLocalizations.of(context)!;
    if (text == l10n.timeChipNow) {
      return TimeChipType.now;
    } else if (text == l10n.timeChipJustNow) {
      return TimeChipType.past;
    } else if (text.contains('지남') ||
        text.contains('overdue') ||
        text == l10n.nowYesterday ||
        text.endsWith('전') ||
        text.endsWith('ago') ||
        text.endsWith('left')) {
      if (text.contains('지남') ||
          text.contains('overdue') ||
          text == l10n.nowYesterday ||
          text.endsWith('ago')) {
        return TimeChipType.past;
      }
      if (text.endsWith('전') || text.endsWith('left')) {
        return TimeChipType.upcoming;
      }
      return TimeChipType.upcoming;
    } else {
      return TimeChipType.upcoming;
    }
  }

  /// Manager Quick Card용 Time Chip 텍스트
  String? _getManagerTimeChipText(HomeCardModel model) {
    return _getTimeChipText(model);
  }

  /// Manager Quick Card용 Time Chip 타입
  TimeChipType? _getManagerTimeChipType(HomeCardModel model) {
    return _getTimeChipType(model);
  }

  /// Secondary Executor Card용 Time Chip 텍스트
  String? _getSecondaryTimeChipText(HomeCardModel model) {
    return _getTimeChipText(model);
  }

  /// Secondary Executor Card용 Time Chip 타입
  TimeChipType? _getSecondaryTimeChipType(HomeCardModel model) {
    return _getTimeChipType(model);
  }

  /// 기록의 시선 텍스트 생성 (If-Then 팁 + 스트릭 독려)
  String? _getRecordGazeText(HomeCardModel model) {
    if (model.state != HomeCardState.nowAction &&
        model.state != HomeCardState.overdue) {
      return null;
    }

    final l10n = AppLocalizations.of(context)!;
    // 스트릭 기반 독려 메시지
    final streak = model.streakCount;
    if (streak != null && streak >= 5) {
      return l10n.nowKeepFlowing;
    }

    // description에 if-then 패턴이 있으면 리마인더로 활용
    final desc = model.plan?.items.firstOrNull?.description;
    if (desc != null && desc.isNotEmpty) {
      if (desc.contains('하면') ||
          desc.contains('되면') ||
          desc.contains('나면') ||
          desc.toLowerCase().contains('when ') ||
          desc.toLowerCase().contains('if ')) {
        return desc;
      }
    }

    // if-then 팁 로테이션 (날짜 기반)
    final tips = [
      l10n.nowGuideWhen,
      l10n.nowGuideSmallStart,
      l10n.nowGuideBetterToday,
    ];
    final dayIndex = DateTime.now().day % tips.length;
    return tips[dayIndex];
  }

  @override
  Widget build(BuildContext context) {
    // Provider 구독
    final homeStateAsync = ref.watch(nowTabViewModelProvider);

    // 데이터 변경 감지하여 애니메이션 트리거
    ref.listen(nowTabViewModelProvider, (previous, next) {
      if (!next.hasValue) return;

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

      if (previous?.value == null) {
        _onDataLoaded();
        return;
      }

      final prevUiState = previous!.value!;
      final nextUiState = next.value!;

      // Manager Card 변경 여부 확인 (리스트 비교)
      final prevManagerId = prevUiState.managerCards.firstOrNull?.plan?.id;
      final nextManagerId = nextUiState.managerCards.firstOrNull?.plan?.id;
      final managerChanged =
          prevUiState.managerCards.length != nextUiState.managerCards.length ||
          prevManagerId != nextManagerId;

      // Primary Card 변경 여부 확인
      final primaryChanged =
          prevUiState.primaryCard?.plan?.id !=
          nextUiState.primaryCard?.plan?.id;

      // 에러 핸들링
      if (next.hasError && !next.isLoading) {
        // 기존 데이터가 있는 상태에서 에러가 발생했을 때만 다이얼로그 표시 (SnackBar 대신)
        // 화면 전체가 에러인 경우는 build()의 error 위젯이 처리
        if (previous.hasError != true) {
          final error = next.error;
          final dl10n = AppLocalizations.of(context)!;
          String errorMessage = dl10n.historyErrorUnknown;
          String? errorUrl;

          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            errorMessage = dl10n.historyErrorIndexMissing;

            // Extract URL if possible (very rough regex)
            final urlRegExp = RegExp(
              r'https://console\.firebase\.google\.com[^\s]*',
            );
            final match = urlRegExp.firstMatch(error.toString());
            if (match != null) {
              errorUrl = match.group(0);
            }
          } else {
            errorMessage = error.toString();
          }

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(dl10n.nowErrorTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage),
                  if (errorUrl != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      dl10n.nowErrorCreationLink,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    AppUnderlinedText.selectable(
                      errorUrl,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(dl10n.nowOk),
                ),
              ],
            ),
          );
        }
      }

      // 카드의 식별자가 변경되었을 때만 애니메이션 재시작
      if (managerChanged || primaryChanged) {
        _onDataLoaded();
      }
    });

    // 첫 진입 시에도 실행되도록 보장
    if (_animationController.status == AnimationStatus.dismissed &&
        homeStateAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onDataLoaded());
    }

    // 에러가 있어도 데이터가 있으면 보여줌 (Dialog로 에러 알림)
    // 데이터가 없고 에러만 있으면 빈 화면 (Dialog로 에러 알림)
    // 데이터가 없고 로딩 중이면 로딩 표시

    if (homeStateAsync.hasValue) {
      final uiState = homeStateAsync.value!;
      // 기존 data: (...) 블록 내용 사용
      final primaryExecutorCard = uiState.primaryCard;
      final secondaryExecutorCards = uiState.secondaryCards;
      final managerCards = uiState.managerCards;
      _maybeAutoAcknowledgePoke(primaryExecutorCard);

      return Stack(
        children: [
          Column(
            children: [
              // 헤더
              QuietHeader(
                partnerName: uiState.partnerProfile?.displayName,
                periodState: uiState.headerPeriodState,
                onSettingsTap: null,
              ),
              // Now Card
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 24,
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Executor Area (Primary Action)
                        if (primaryExecutorCard != null) ...[
                          FadeTransition(
                            opacity: _primaryFadeAnimation,
                            child: ScaleTransition(
                              scale: _primaryScaleAnimation,
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(
                                        0,
                                        0.15,
                                      ), // 시작/사라질 때 더 아래로
                                      end: Offset.zero, // 정상 위치
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Curves.easeIn,
                                      ),
                                    ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.9,
                                    child: _PrimaryExecutorCard(
                                      model: primaryExecutorCard,
                                      onDidIt: _handleDidIt,
                                      onFocusTimer: _handleFocusTimer,
                                      onSkip: _handleSkip,
                                      onRest: _handleRest,
                                      onCreatePlan: _handleCreatePlan,
                                      onModify: () => _handleModify(
                                        primaryExecutorCard,
                                      ), // Added
                                      onAcceptPromise: () =>
                                          _handleRespondPromise(
                                            primaryExecutorCard,
                                            true,
                                          ),
                                      onRejectPromise: () =>
                                          _handleRespondPromise(
                                            primaryExecutorCard,
                                            false,
                                          ),
                                      onContinueAfterSettlement: () =>
                                          _handleContinueAfterSettlement(
                                            primaryExecutorCard,
                                          ),
                                      onExitAfterSettlement: () =>
                                          _handleExitAfterSettlement(
                                            primaryExecutorCard,
                                          ),
                                      onAcknowledgePromiseSettled: () =>
                                          _handleAcknowledgePromiseSettled(
                                            primaryExecutorCard,
                                          ),
                                      onTap: () =>
                                          _handleCardTap(primaryExecutorCard),
                                      timeChipText: _getTimeChipText(
                                        primaryExecutorCard,
                                      ),
                                      timeChipType: _getTimeChipType(
                                        primaryExecutorCard,
                                      ),
                                      recordGazeText: _getRecordGazeText(
                                        primaryExecutorCard,
                                      ),
                                      exactTimeText: _getExactTimeText(
                                        primaryExecutorCard,
                                      ),
                                    ),
                                    // Glassmorphism wrapper
                                  ).wrapWithGlass(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (secondaryExecutorCards.isEmpty &&
                            managerCards.isEmpty) ...[
                          // Empty State (No Plan)
                          FadeTransition(
                            opacity: _primaryFadeAnimation,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: 0.9,
                                child: _PrimaryExecutorCard(
                                  model: const HomeCardModel(
                                    state: HomeCardState.emptyPlan,
                                  ),
                                  onCreatePlan: _handleCreatePlan,
                                  onTap: _handleCreatePlan,
                                ).wrapWithGlass(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Secondary Executor Cards (My Contexts)
                        if (secondaryExecutorCards.isNotEmpty) ...[
                          ...secondaryExecutorCards.map(
                            (state) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FadeTransition(
                                opacity: _secondaryFadeAnimation,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.85,
                                    child: _SecondaryExecutorCard(
                                      model: state,
                                      timeChipText: _getSecondaryTimeChipText(
                                        state,
                                      ),
                                      timeChipType: _getSecondaryTimeChipType(
                                        state,
                                      ),
                                      onReconcile: () {
                                        ref
                                            .read(
                                              nowTabViewModelProvider.notifier,
                                            )
                                            .dispatch(const RefreshIntent());
                                      },
                                      exactTimeText: _getExactTimeText(state),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        // Manager Area (Partner's Requests)
                        if (managerCards.isNotEmpty) ...[
                          ...managerCards.map((card) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FadeTransition(
                                opacity: _managerFadeAnimation,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.88,
                                    child: _ManagerQuickCard(
                                      model: card,
                                      partnerName: card.partnerName,
                                      onCheckIt: () => _handleCheckIt(card),
                                      onReject: () =>
                                          _handleReject(card), // Added
                                      onCheer: () => _handleCheer(card),
                                      onPass: () => _handlePass(card),
                                      onSimpleCheer: () =>
                                          _handleSimpleCheer(card),
                                      onMoreCheer: () => _handleMoreCheer(card),
                                      onPokeUser: () =>
                                          _handlePokeUser(card), // Added
                                      onPokePartner: () =>
                                          _handlePokePartner(card), // Added
                                      onRescue: () => _handleRescue(card),
                                      onProposePromise: () =>
                                          _handleProposePromise(card),
                                      onAcknowledgePromiseSettled: () =>
                                          _handleAcknowledgePromiseSettled(card),
                                      timeChipText: _getManagerTimeChipText(
                                        card,
                                      ),
                                      timeChipType: _getManagerTimeChipType(
                                        card,
                                      ),
                                      exactTimeText: _getExactTimeText(card),
                                    ).wrapWithGlass(),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                        // Footer
                        const _ContextFooter(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Debug Fake State Toggle Button (Debug Only)
          if (kDebugMode && !BuildFlags.storeScreenshotMode)
            Positioned(
              bottom: 120, // Raised to avoid bottom nav overlap
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.bug_report, size: 20),
                onPressed: () {
                  _showFakeStateSelector(context, ref);
                },
              ),
            ),
        ],
      );
    } else if (homeStateAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      // 에러 상황이나 빈 상황이지만 데이터가 없는 경우 -> 빈 화면 반환 (다이얼로그가 에러를 보여줌)
      // 혹은 "다시 시도" 버튼 정도는 보여줄 수 있음.
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.nowRetryLater,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleSimpleCheer(HomeCardModel card) async {
    if (card.plan?.id == null) return;

    // Show Dialog to input feedback (consistent with History tab)
    final l10n = AppLocalizations.of(context)!;
    final feedback = await showDialog<String>(
      context: context,
      builder: (context) => ActionNoteDialog(
        title: card.plan?.items.firstOrNull?.title ?? l10n.nowPartnerActionFallback,
        hintText: l10n.nowActionNoteHint,
        buttonLabel: l10n.nowVerifyAndSend,
      ),
    );

    if (feedback != null) {
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(
              CheerPartnerActionIntent(
                card.plan!.id!,
                '👍',
                message: feedback.isEmpty ? null : feedback,
              ),
            );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nowCheerFailed)));
        }
      }
    }
  }

  void _handleMoreCheer(HomeCardModel card) {
    if (card.plan?.id == null) return;
    _showReactionBottomSheet(context, card.plan!.id!);
  }

  void _showReactionBottomSheet(BuildContext context, String planId) {
    final l10n = AppLocalizations.of(context)!;
    final messageController = TextEditingController();
    String selectedReaction = '🔥';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final mediaQuery = MediaQuery.of(context);
            final bottomInset = mediaQuery.viewInsets.bottom > 0
                ? mediaQuery.viewInsets.bottom
                : mediaQuery.viewPadding.bottom;

            return Container(
              constraints: BoxConstraints(
                maxHeight: mediaQuery.size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.disabled,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.cheerSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: ['🔥', '❤️', '👏', '👍', '😮', '😢', '💪', '✨']
                          .map((emoji) {
                            final isSelected = selectedReaction == emoji;
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  selectedReaction = emoji;
                                });
                              },
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: CenteredEmoji(emoji, size: 28),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: l10n.cheerMessageHint,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(nowTabViewModelProvider.notifier)
                                .dispatch(
                                  CheerPartnerActionIntent(
                                    planId,
                                    selectedReaction,
                                    message: messageController.text.trim(),
                                  ),
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.nowCheerFailed)),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.cheerSend,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(messageController.dispose);
  }

  void _showFakeStateSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Debug: FakeState 선택',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: NowTabFakeStates.all.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text(
                        'Primary: ${entry.value.primaryCard != null ? "O" : "X"}, '
                        'Secondary: ${entry.value.secondaryCards.length}, '
                        'Manager: ${entry.value.managerCards.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(nowTabViewModelProvider.notifier)
                            .setFakeState(entry.value);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ 적용됨: ${entry.key}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(nowTabViewModelProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 실제 데이터로 복구됨'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                  ),
                  icon: Icon(Icons.refresh, color: AppColors.primary),
                  label: Text(
                    '실제 데이터로 복구',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrimaryExecutorCard extends StatelessWidget {
  final HomeCardModel model;
  final VoidCallback? onTap;
  final VoidCallback? onDidIt;
  final VoidCallback? onFocusTimer;
  final VoidCallback? onSkip;
  final VoidCallback? onRest; // 휴식권
  final VoidCallback? onCreatePlan;
  final VoidCallback? onModify; // Added
  final VoidCallback? onAcceptPromise;
  final VoidCallback? onRejectPromise;
  final VoidCallback? onContinueAfterSettlement;
  final VoidCallback? onExitAfterSettlement;
  final VoidCallback? onAcknowledgePromiseSettled;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? recordGazeText;
  final String? exactTimeText;

  const _PrimaryExecutorCard({
    required this.model,
    this.onDidIt,
    this.onFocusTimer,
    this.onSkip,
    this.onRest,
    this.onCreatePlan,
    this.onModify, // Added
    this.onAcceptPromise,
    this.onRejectPromise,
    this.onContinueAfterSettlement,
    this.onExitAfterSettlement,
    this.onAcknowledgePromiseSettled,
    this.onTap,
    this.timeChipText,
    this.timeChipType,
    this.recordGazeText,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        color: AppColors.surface.withValues(alpha: 0.7),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (model.state == HomeCardState.poked) ...[
                _PokeBadge(partnerName: model.partnerName),
                const SizedBox(height: 12),
              ],
              if (timeChipText != null && timeChipType != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Week indicator removed per user request
                    exactTimeText != null
                        ? Tooltip(
                            message: exactTimeText!,
                            triggerMode: TooltipTriggerMode.longPress,
                            child: TimeChip(
                              text: timeChipText!,
                              type: timeChipType!,
                            ),
                          )
                        : TimeChip(text: timeChipText!, type: timeChipType!),
                  ],
                ),
              if (timeChipText != null && timeChipType != null)
                const SizedBox(height: 12),
              _buildMessage(context, l10n),
              if (recordGazeText != null) ...[
                const SizedBox(height: 8),
                Text(
                  recordGazeText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
              if (_shouldShowActivePromiseChip()) ...[
                const SizedBox(height: 12),
                ActivePromiseChip(plan: model.plan!),
              ],
              const SizedBox(height: 20),
              _buildButton(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowActivePromiseChip() {
    final plan = model.plan;
    final promise = plan?.promise;
    if (plan == null || promise == null) return false;
    if (promise.status != PromiseStatus.active) return false;
    return model.state == HomeCardState.nowAction ||
        model.state == HomeCardState.poked ||
        model.state == HomeCardState.overdue;
  }

  /// TodayComplete + 다중 플랜용 메시지 영역.
  /// 카운트 헤드라인 + 각 플랜의 체크리스트 row(스트릭이 있으면 작은 뱃지).
  Widget _buildMultiPlanCompleteMessage(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final plans = model.completedPlans;
    final children = <Widget>[
      Text(
        l10n.nowTodayAllDone(plans.length),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        textAlign: TextAlign.left,
      ),
      const SizedBox(height: 12),
    ];

    for (var i = 0; i < plans.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 8));
      children.add(_buildCompletedPlanRow(context, plans[i]));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildCompletedPlanRow(BuildContext context, Plan plan) {
    final title = plan.items.firstOrNull?.title ?? '';
    final streak = plan.currentStreak;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
        if (streak >= 2) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  '$streak',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    // 오늘 완료한 플랜이 둘 이상이면 체크리스트로 보여줘 성취의 규모가 드러나게 한다.
    if (model.state == HomeCardState.todayComplete &&
        model.completedPlans.length >= 2) {
      return _buildMultiPlanCompleteMessage(context, l10n);
    }

    final title = model.plan?.items.firstOrNull?.title;
    final List<Widget> children = [];

    // Title (if applicable)
    if (title != null) {
      children.add(
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
        case HomeCardState.nextAction: // Type 1-3: 다음 일정
          // Next Action usually uses headerMessage or defaults to nothing special
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
        Text(
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

    // ----------------------------------------------------
    // 1. lastActionNote (실천자 한마디 - 나/파트너 공통)
    // ----------------------------------------------------
    if (model.plan?.lastActionNote != null &&
        model.plan!.lastActionNote!.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
              topLeft: Radius.circular(2),
            ),
          ),
          child: Text(
            model.plan!.lastActionNote!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // 2. lastComment (매니저 피드백/응원)
    // ----------------------------------------------------
    if (model.plan?.lastComment != null &&
        model.plan!.lastComment!.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      // lastCheerType(👍/❤️/💪 같은 리액션 이모지)과 lastComment를 나란히
      // 놓으면 ① 파트너가 보통 코멘트에도 이모지를 같이 치기 때문에 의미가
      // 중복되고 ② 두 Text의 fontSize/strut이 달라 윗선이 어긋난다. 칩 배경이
      // 이미 "응원" 시그널 역할이라 코멘트만 깔끔히 보여주는 게 자연스럽다.
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            model.plan!.lastComment!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  Widget _buildPilotSettlementDetail(BuildContext context, Plan plan) {
    final l10n = AppLocalizations.of(context)!;
    final totalScheduled = _scheduledDaysCount(plan);
    final completed = plan.completedDates.length;
    final feedback = _partnerFeedbackCount(plan);
    final missed = (totalScheduled - completed).clamp(0, totalScheduled);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSettlementMetric(l10n.nowMetricCompleted, l10n.nowMetricDaysSuffix(completed))),
              Expanded(child: _buildSettlementMetric(l10n.nowMetricPartnerReact, l10n.nowMetricCountSuffix(feedback))),
              Expanded(child: _buildSettlementMetric(l10n.nowMetricMissed, l10n.nowMetricDaysSuffix(missed))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completed >= 12
                ? l10n.nowSettlementWinMessage
                : l10n.nowSettlementLoseMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  int _scheduledDaysCount(Plan plan) {
    return plan.scheduledDayCount;
  }

  int _partnerFeedbackCount(Plan plan) {
    var count = plan.verifiedDates.length + plan.rescuedDates.length;
    if (plan.lastCheerAt != null) count++;
    if (plan.lastPokeAt != null) count++;
    return count;
  }

  Widget _buildPromiseDetail(BuildContext context, Promise promise) {
    final l10n = AppLocalizations.of(context)!;
    final isSettled = promise.status == PromiseStatus.settled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promise.reward != null) ...[
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.nowRewardCondition(promise.reward!.targetDays, promise.reward!.description),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSettled)
                  _buildSettlementBadge(context, promise, isReward: true),
              ],
            ),
          ],
          if (promise.reward != null && promise.penalty != null)
            const SizedBox(height: 8),
          if (promise.penalty != null) ...[
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.nowPenaltyCondition(promise.penalty!.targetDays, promise.penalty!.description),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSettled)
                  _buildSettlementBadge(context, promise, isReward: false),
              ],
            ),
          ],
          if (isSettled && promise.settledSuccessDays != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.nowPromiseResult(promise.settledSuccessDays!, promise.settledFailDays ?? 0),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettlementBadge(
    BuildContext context,
    Promise promise, {
    required bool isReward,
  }) {
    final result = promise.settlementResult;
    final bool achieved;
    if (isReward) {
      achieved =
          result == SettlementResult.rewardAchieved ||
          result == SettlementResult.bothMet;
    } else {
      achieved =
          result == SettlementResult.penaltyTriggered ||
          result == SettlementResult.bothMet;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: achieved
            ? (isReward ? AppColors.success : AppColors.error).withValues(
                alpha: 0.15,
              )
            : AppColors.disabled.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        achieved ? (isReward ? AppLocalizations.of(context)!.nowAchieved : AppLocalizations.of(context)!.nowTriggered) : AppLocalizations.of(context)!.nowNotMet,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: achieved
              ? (isReward ? AppColors.success : AppColors.error)
              : AppColors.textDisabled,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPromiseProposedButtons(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRejectPromise,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.nowDecline,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: onAcceptPromise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.nowAccept,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromiseSettledButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAcknowledgePromiseSettled,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.nowPromiseAckButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, AppLocalizations l10n) {
    final buttonTextColor = Colors.white;
    VoidCallback? onPressed;
    String buttonText;

    if (model.state == HomeCardState.pilotSettlement) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinueAfterSettlement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.nowContinueNext4Weeks,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onExitAfterSettlement,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 32),
              padding: const EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: AppUnderlinedText(
              l10n.nowStopHere,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      );
    }

    if (model.state == HomeCardState.nowAction ||
        model.state == HomeCardState.poked) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.overdue) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.emptyPlan) {
      buttonText = l10n.nowCreatePlan;
      onPressed = onCreatePlan;
    } else if (model.state == HomeCardState.rejected) {
      buttonText = l10n.nowModify;
      onPressed = onModify;
    } else if (model.state == HomeCardState.promiseProposed) {
      return _buildPromiseProposedButtons(context);
    } else if (model.state == HomeCardState.promiseSettled) {
      return _buildPromiseSettledButton(context, l10n);
    } else if (model.state == HomeCardState.todayComplete ||
        model.state == HomeCardState.todayEmpty) {
      // "작은 버튼" 요청: TextButton으로 구현
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onCreatePlan,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppUnderlinedText(
                l10n.nowAddMorePlan,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 10),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: buttonTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primaryPressed;
                    }
                    return null;
                  }),
                ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: buttonTextColor,
              ),
            ),
          ),
        ),
        // 지금 할게! (집중 타이머)
        if ((model.state == HomeCardState.nowAction ||
                model.state == HomeCardState.poked) &&
            onFocusTimer != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFocusTimer,
              icon: Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                l10n.nowStartFocusTimer,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        // 휴식권 버튼 (nowAction에서 사용 가능 시)
        if ((model.state == HomeCardState.nowAction ||
                model.state == HomeCardState.poked) &&
            onRest != null &&
            model.plan?.canUseRestToday == true) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRest,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 32),
              padding: const EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: AppUnderlinedText(
              l10n.nowRestToday,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
        if (model.state == HomeCardState.overdue && onSkip != null) ...[
          const SizedBox(height: 12),
          // 휴식권 우선, 없으면 skip
          if (onRest != null && model.plan?.canUseRestToday == true)
            TextButton(
              onPressed: onRest,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 32),
                padding: const EdgeInsets.symmetric(vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: AppUnderlinedText(
                l10n.nowRestToday,
                style: const TextStyle(fontSize: 13),
              ),
            )
          else
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 32),
                padding: const EdgeInsets.symmetric(vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: AppUnderlinedText(
                l10n.nowActionSkipToday,
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }
}

class _SecondaryExecutorCard extends StatelessWidget {
  final HomeCardModel model;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? exactTimeText;

  final VoidCallback? onReconcile;

  const _SecondaryExecutorCard({
    required this.model,
    this.timeChipText,
    this.timeChipType,
    this.onReconcile,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Checked 상태인 경우 다른 레이아웃 적용
    if (model.state == HomeCardState.todayComplete) {
      return _buildCheckedCard(context, l10n);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Fixed: Left alignment
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (model.partnerName != null) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary,
                        backgroundImage: model.partnerImageUrl != null
                            ? NetworkImage(model.partnerImageUrl!)
                            : null,
                        child: model.partnerImageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Week indicator removed
                  ],
                ),
                if (timeChipText != null && timeChipType != null) ...[
                  if (exactTimeText != null)
                    Tooltip(
                      message: exactTimeText!,
                      triggerMode: TooltipTriggerMode.longPress,
                      child: TimeChip(text: timeChipText!, type: timeChipType!),
                    )
                  else
                    TimeChip(text: timeChipText!, type: timeChipType!),
                ],
              ],
            ),
            if (timeChipText != null && timeChipType != null)
              const SizedBox(height: 8),
            _buildMessage(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedCard(BuildContext context, AppLocalizations l10n) {
    final title = model.plan?.items.firstOrNull?.title ?? '';
    final now = DateTime.now();
    final dateStr = '${now.month}.${now.day} (${_getWeekdayStr(now.weekday, l10n)})';

    // 긍정 메시지 중 하나 선택
    final messages = [
      l10n.nowLateCompletion,
      l10n.nowLateJustInTime,
      l10n.nowWithinToday,
    ];
    final message = messages[now.second % messages.length];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.nowStatusActuallyDone,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title.isNotEmpty ? title : l10n.nowMissedPlanFallback,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // 작은 말풍선 스타일 (Low Intensity)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  topLeft: Radius.circular(2),
                ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdayStr(int weekday, AppLocalizations l10n) {
    switch (weekday) {
      case 1:
        return l10n.planDetailDayMon;
      case 2:
        return l10n.planDetailDayTue;
      case 3:
        return l10n.planDetailDayWed;
      case 4:
        return l10n.planDetailDayThu;
      case 5:
        return l10n.planDetailDayFri;
      case 6:
        return l10n.planDetailDaySat;
      case 7:
        return l10n.planDetailDaySun;
      default:
        return '';
    }
  }

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
    final title = model.plan?.items.firstOrNull?.title;
    final List<Widget> children = [];

    // Title
    if (title != null) {
      children.add(
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.4,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
    }

    String? statusMessage;
    // Secondary card doesn't usually use subMessage but for consistency can add if needed.
    // However, specs target mostly primary card.

    if (model.state == HomeCardState.partnerAction) {
      // "000님이 아침 약 챙겨먹기를... 했어요"
      // final action = ...
      // For now, simpler text construction
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '${_particleEulReul(title ?? '', l10n.localeName)}\n'),
                TextSpan(
                  text: l10n.nowPartnerDidIt,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Description
          if (model.plan?.items.firstOrNull?.description != null)
            Text(
              model.plan!.items.firstOrNull!.description!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          // ----------------------------------------------------
          // 1. lastActionNote (실천자 한마디)
          // ----------------------------------------------------
          if (model.plan?.lastActionNote != null &&
              model.plan!.lastActionNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  topLeft: Radius.circular(2),
                ),
              ),
              child: Text(
                model.plan!.lastActionNote!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          // ----------------------------------------------------
          // 2. lastComment (매니저 피드백)
          // ----------------------------------------------------
          if (model.plan?.lastComment != null &&
              model.plan!.lastComment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            // 위 응원 pill과 동일: lastCheerType은 코멘트 내 이모지와 중복되고
            // 두 Text의 strut이 달라 정렬이 어긋난다. 코멘트만 그대로 보여준다.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                model.plan!.lastComment!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
    }

    switch (model.state) {
      case HomeCardState.partnerAction:
        statusMessage = l10n.nowVerifyingDeadline;
        break;
      case HomeCardState.todayEmpty:
        statusMessage = l10n.nowQuietRest;
        break;
      case HomeCardState.overdue:
        // statusMessage = l10n.timePassedActorMessage;
        break;
      default:
        break;
    }

    if (statusMessage != null) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 4));
      children.add(
        Text(
          statusMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: title != null
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            height: 1.4,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _ManagerQuickCard extends StatelessWidget {
  final HomeCardModel model;
  final String? partnerName;
  final VoidCallback? onCheckIt;
  final VoidCallback? onCheer;
  final VoidCallback? onPass;
  final VoidCallback? onSimpleCheer;
  final VoidCallback? onMoreCheer;
  final VoidCallback? onReject;
  final VoidCallback? onPokeUser;
  final VoidCallback? onPokePartner; // Added
  final VoidCallback? onRescue; // 실천 인정
  final VoidCallback? onProposePromise;
  final VoidCallback? onAcknowledgePromiseSettled;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? exactTimeText;

  const _ManagerQuickCard({
    required this.model,
    this.partnerName,
    this.onCheckIt,
    this.onCheer,
    this.onPass,
    this.onSimpleCheer,
    this.onMoreCheer,
    this.onReject,
    this.onPokeUser,
    this.onPokePartner,
    this.onRescue,
    this.onProposePromise,
    this.onAcknowledgePromiseSettled,
    this.timeChipText,
    this.timeChipType,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPartnerTodayComplete =
        model.state == HomeCardState.partnerTodayComplete;

    String headerText;
    if (isPartnerTodayComplete) {
      headerText = l10n.nowHeaderTodayAllDone;
    } else if (model.state == HomeCardState.partnerAction) {
      headerText = l10n.nowHeaderConfirmAndPull;
    } else if (model.state == HomeCardState.partnerPlanCreate ||
        model.state == HomeCardState.partnerPlanModify) {
      if (model.headerMessage == '조정 중' ||
          model.headerMessage == '같이 맞춰보는 중이에요' ||
          model.headerMessage == 'Adjusting' ||
          model.headerMessage == 'Working it out together') {
        headerText = l10n.nowPartnerAdjusting;
      } else {
        headerText = l10n.nowPartnerProposed;
      }
    } else if (model.state == HomeCardState.partnerNoPlan) {
      headerText = l10n.nowHeaderWaiting;
    } else if (model.state == HomeCardState.partnerPromiseProposed) {
      headerText = l10n.nowHeaderWaitingAccept;
    } else if (model.state == HomeCardState.promiseSettled) {
      headerText = l10n.nowHeaderPromiseResult;
    } else {
      headerText = model.headerMessage ?? l10n.homeReceivedMessage;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.surface.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                if (partnerName != null) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    backgroundImage: model.partnerImageUrl != null
                        ? NetworkImage(model.partnerImageUrl!)
                        : null,
                    child: model.partnerImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week indicator removed
                      Text(
                        headerText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                if (timeChipText != null && timeChipType != null) ...[
                  const SizedBox(width: 8),
                  if (exactTimeText != null)
                    Tooltip(
                      message: exactTimeText!,
                      triggerMode: TooltipTriggerMode.longPress,
                      child: TimeChip(text: timeChipText!, type: timeChipType!),
                    )
                  else
                    TimeChip(text: timeChipText!, type: timeChipType!),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Title (Diff Aware)
            if (!isPartnerTodayComplete &&
                model.plan?.items.firstOrNull?.title != null) ...[
              SizedBox(
                width: double.infinity,
                child: _buildDiffText(
                  context,
                  current: model.plan!.items.firstOrNull!.title,
                  previous: model.previousPlan?.items.firstOrNull?.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            // Scale & Period
            if (!isPartnerTodayComplete && model.plan != null)
              _buildPlanDetails(context, model.plan!, l10n),
            const SizedBox(height: 8),
            // Description (Diff Aware)
            if (!isPartnerTodayComplete &&
                model.plan?.items.firstOrNull?.description != null) ...[
              SizedBox(
                width: double.infinity,
                child: _buildDiffText(
                  context,
                  current: model.plan!.items.firstOrNull!.description,
                  previous: model.previousPlan?.items.firstOrNull?.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isPartnerTodayComplete) ...[
              _buildPartnerTodayCompleteMessage(context),
            ],
            // Button (Only for partnerActionShare/partnerPlanShare that needs action)
            if (model.state == HomeCardState.partnerPlanCreate ||
                model.state == HomeCardState.partnerPlanModify) ...[
              if (model.headerMessage != '함께하는 중' && model.headerMessage != 'Working together') ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.nowAdjust,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onCheckIt,
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ).copyWith(
                              overlayColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return AppColors.primaryPressed;
                                    }
                                    return null;
                                  }),
                            ),
                        child: Text(
                          l10n.nowApprove,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],

            // Button (Partner No Plan - Poke)
            if (model.state == HomeCardState.partnerNoPlan) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  l10n.nowPartnerNoNewPlanGuide,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPokeUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.nowKnockMakePlan,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else if (model.state == HomeCardState.partnerPoke) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  (model.headerMessage == '놓친 약속이 떴어요' || model.headerMessage == 'Missed promise appeared')
                      ? l10n.nowPartnerMissedPokeBody(partnerName ?? l10n.nowPartnerFallback2)
                      : l10n.nowPartnerQuietPokeBody(partnerName ?? l10n.nowPartnerFallback2),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPokePartner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.nowKnockPull,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // 실천 인정 버튼 (어제 놓친 경우)
              if (model.canRescue && onRescue != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onRescue,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        AppUnderlinedText(
                          l10n.nowRescueYesterday,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else if (model.state == HomeCardState.partnerAction ||
                model.state == HomeCardState.partnerTodayComplete) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSimpleCheer ?? onCheckIt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.nowVerifyAndCheer,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (model.state == HomeCardState.partnerPromiseProposed) ...[
              const SizedBox(height: 12),
              if (model.plan?.promise != null)
                _buildManagerPromiseDetail(context, model.plan!.promise!),
            ] else if (model.state == HomeCardState.promiseSettled) ...[
              const SizedBox(height: 12),
              if (model.plan?.promise != null)
                _buildManagerPromiseDetail(context, model.plan!.promise!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAcknowledgePromiseSettled,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.nowPromiseAckButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            // "약속 걸기" 버튼 (partnerPoke, partnerPlanCreate에서 약속 없을 때)
            if ((model.state == HomeCardState.partnerPoke ||
                    model.state == HomeCardState.partnerPlanCreate ||
                    model.state == HomeCardState.partnerAction) &&
                (model.plan?.promise == null ||
                    model.plan?.promise?.status == PromiseStatus.rejected)) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onProposePromise,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      AppUnderlinedText(
                        l10n.nowMakePromise,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerTodayCompleteMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedPartnerName = (partnerName?.trim().isNotEmpty ?? false)
        ? partnerName!.trim()
        : l10n.nowPartnerFallback2;
    final title = model.plan?.items.firstOrNull?.title;
    final note = model.plan?.lastActionNote?.trim();

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.nowPartnerAllDone(resolvedPartnerName),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.nowQuickCheckHelp,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (title != null && title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.nowLastAction(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  topLeft: Radius.circular(2),
                ),
              ),
              child: Text(
                note,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManagerPromiseDetail(BuildContext context, Promise promise) {
    final l10n = AppLocalizations.of(context)!;
    final isSettled = promise.status == PromiseStatus.settled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promise.reward != null) ...[
            Text(
              l10n.nowRewardLine(promise.reward!.targetDays, promise.reward!.description),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (promise.reward != null && promise.penalty != null)
            const SizedBox(height: 4),
          if (promise.penalty != null) ...[
            Text(
              l10n.nowPenaltyLine(promise.penalty!.targetDays, promise.penalty!.description),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (isSettled && promise.settledSuccessDays != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.nowResultLine(promise.settledSuccessDays!, promise.settledFailDays ?? 0),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (promise.settlementResult != null) ...[
              const SizedBox(height: 4),
              Text(
                _settlementResultText(promise.settlementResult!, l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 4),
            Text(
              l10n.nowWaitingApproval,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _settlementResultText(SettlementResult result, AppLocalizations l10n) {
    switch (result) {
      case SettlementResult.rewardAchieved:
        return l10n.nowRewardAchievedTitle;
      case SettlementResult.penaltyTriggered:
        return l10n.nowPenaltyTriggeredTitle;
      case SettlementResult.bothMet:
        return l10n.nowBothTitle;
      case SettlementResult.neitherMet:
        return l10n.nowConditionNotMet;
    }
  }

  Widget _buildDiffText(
    BuildContext context, {
    required String? current,
    required String? previous,
    required TextStyle? style,
  }) {
    // 변경된 내용이 없거나 previous가 없으면 현재 내용만 표시
    if (previous == null || current == previous) {
      return Text(current ?? '', style: style, textAlign: TextAlign.left);
    }

    // 변경된 내용이 있으면 취소선(Before) -> Normal(After) 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          previous,
          style: style?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            // 취소선 스타일 조정 (선택 사항)
            decorationColor: AppColors.textSecondary,
          ),
          textAlign: TextAlign.left,
        ),
        // 약간의 간격? 원한다면 추가. 현재 요구사항엔 명시 없음.
        Text(current ?? '', style: style, textAlign: TextAlign.left),
      ],
    );
  }

  Widget _buildPlanDetails(
    BuildContext context,
    Plan plan,
    AppLocalizations l10n,
  ) {
    if (plan.items.isEmpty) return const SizedBox.shrink();
    final item = plan.items.first;

    // Period: 10.01(Mon) - 10.28(Sun)
    final start = plan.startDate;
    final end = plan.endDate;

    String getWeekday(DateTime d) =>
        TimeFormatter.getWeekdayName(l10n, d.weekday);
    final periodStr =
        '${start.month}.${start.day}(${getWeekday(start)}) - ${end.month}.${end.day}(${getWeekday(end)})';

    // Days: Mon, Wed, Fri
    final daysStr = item.days.length == 7
        ? l10n.frequencyEveryday
        : item.days
              .map((d) => TimeFormatter.getWeekdayName(l10n, d))
              .join(', ');

    return SizedBox(
      width: double.infinity,
      child: Text(
        '$periodStr · $daysStr',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14, // Increased
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

class _ContextFooter extends StatelessWidget {
  const _ContextFooter();

  @override
  Widget build(BuildContext context) {
    final contextInfo = <String>[];
    if (contextInfo.isEmpty) return const SizedBox.shrink();

    return Column(
      children: contextInfo.map((info) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            info,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}

// _ReconcileMenu removed per user request (was unused after UI updates)

@visibleForTesting
class PromiseProposalSheet extends StatefulWidget {
  final Plan plan;
  final DateTime? asOf;

  const PromiseProposalSheet({super.key, required this.plan, this.asOf});

  @override
  State<PromiseProposalSheet> createState() => _PromiseProposalSheetState();
}

class _PromiseProposalSheetState extends State<PromiseProposalSheet> {
  bool _enableReward = true;
  bool _enablePenalty = false;
  final _rewardDescController = TextEditingController();
  final _penaltyDescController = TextEditingController();
  late int _rewardDays;
  late int _penaltyDays;
  late final DateTime _asOf;

  int get _scheduledDays => widget.plan.scheduledDayCount;
  int get _rewardDaysLimit => widget.plan.rewardTargetDaysLimit(asOf: _asOf);
  int get _penaltyDaysLimit => widget.plan.penaltyTargetDaysLimit(asOf: _asOf);
  int get _durationDays => widget.plan.calendarDurationDays;
  int get _completedDays => widget.plan.completedDayCount(asOf: _asOf);
  int get _failedDays => widget.plan.failedDayCount(asOf: _asOf);
  int get _remainingDays => widget.plan.remainingScheduledDayCount(asOf: _asOf);

  @override
  void initState() {
    super.initState();
    _asOf = widget.asOf ?? DateTime.now();
    _rewardDays = _defaultRewardDays();
    _penaltyDays = _defaultPenaltyDays();
  }

  @override
  void dispose() {
    _rewardDescController.dispose();
    _penaltyDescController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (!_enableReward && !_enablePenalty) return false;
    if (_enableReward && _rewardDescController.text.trim().isEmpty) {
      return false;
    }
    if (_enablePenalty && _penaltyDescController.text.trim().isEmpty) {
      return false;
    }
    if (_enableReward && !_isTargetDaysValid(_rewardDays, _rewardDaysLimit)) {
      return false;
    }
    if (_enablePenalty &&
        !_isTargetDaysValid(_penaltyDays, _penaltyDaysLimit)) {
      return false;
    }
    return true;
  }

  bool _isTargetDaysValid(int days, int maxDays) {
    return days >= 1 && days <= maxDays;
  }

  int _clampTargetDays(int days, int maxDays) {
    if (days < 1) return 1;
    if (days > maxDays) return maxDays;
    return days;
  }

  int _defaultRewardDays() {
    final additionalSuccesses = _remainingDays == 0
        ? 0
        : max(1, (_remainingDays * 0.7).ceil());
    final target = _completedDays + additionalSuccesses;
    final baseline = _completedDays == 0 ? min(20, target) : target;
    return _clampTargetDays(baseline, _rewardDaysLimit);
  }

  int _defaultPenaltyDays() {
    if (_failedDays == 0) {
      return _clampTargetDays(min(10, _penaltyDaysLimit), _penaltyDaysLimit);
    }

    final additionalFailures = _remainingDays == 0
        ? 0
        : max(1, (_remainingDays * 0.3).ceil());
    return _clampTargetDays(
      _failedDays + additionalFailures,
      _penaltyDaysLimit,
    );
  }

  void _setRewardDays(int days) {
    setState(() => _rewardDays = _clampTargetDays(days, _rewardDaysLimit));
  }

  void _setPenaltyDays(int days) {
    setState(() => _penaltyDays = _clampTargetDays(days, _penaltyDaysLimit));
  }

  String _durationSummary(AppLocalizations l10n) {
    if (_durationDays == _scheduledDays) {
      return l10n.nowTotalDaysOnly(_durationDays);
    }
    return l10n.nowTotalDaysScheduled(_durationDays, _scheduledDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final bottomInset = keyboardInset > 0
        ? keyboardInset
        : mediaQuery.viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.nowMakePromiseTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.nowMakePromiseSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _durationSummary(l10n),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.nowProgressLine(_completedDays, _failedDays, _remainingDays),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.nowMaxLimitsLine(_rewardDaysLimit, _penaltyDaysLimit),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 보상 섹션
            _buildSectionToggle(
              title: l10n.nowRewardTitle,
              enabled: _enableReward,
              onToggle: (v) => setState(() => _enableReward = v),
            ),
            if (_enableReward) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _rewardDescController,
                decoration: InputDecoration(
                  hintText: l10n.nowRewardHint,
                  hintStyle: TextStyle(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLength: 100,
                onChanged: (_) => setState(() {}),
              ),
              _buildDaysPicker(
                label: l10n.nowRewardTargetLabel,
                days: _rewardDays,
                maxDays: _rewardDaysLimit,
                onChanged: _setRewardDays,
              ),
            ],

            const SizedBox(height: 16),

            // 벌칙 섹션
            _buildSectionToggle(
              title: l10n.nowPenaltyTitle,
              enabled: _enablePenalty,
              onToggle: (v) => setState(() => _enablePenalty = v),
            ),
            if (_enablePenalty) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _penaltyDescController,
                decoration: InputDecoration(
                  hintText: l10n.nowPenaltyHint,
                  hintStyle: TextStyle(color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLength: 100,
                onChanged: (_) => setState(() {}),
              ),
              _buildDaysPicker(
                label: l10n.nowPenaltyTargetLabel,
                days: _penaltyDays,
                maxDays: _penaltyDaysLimit,
                onChanged: _setPenaltyDays,
              ),
            ],

            const SizedBox(height: 24),

            // 제출 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid
                    ? () {
                        Navigator.pop(context, (
                          reward: _enableReward
                              ? PromiseReward(
                                  description: _rewardDescController.text
                                      .trim(),
                                  targetDays: _rewardDays,
                                )
                              : null,
                          penalty: _enablePenalty
                              ? PromisePenalty(
                                  description: _penaltyDescController.text
                                      .trim(),
                                  targetDays: _penaltyDays,
                                )
                              : null,
                        ));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor: AppColors.disabled,
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.nowProposePromise,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionToggle({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onToggle,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDaysPicker({
    required String label,
    required int days,
    required int maxDays,
    required ValueChanged<int> onChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        IconButton(
          onPressed: days > 1 ? () => onChanged(days - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.nowDaysSuffix(days),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: days < maxDays ? () => onChanged(days + 1) : null,
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.nowMaxDaysLabel(maxDays),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

extension GlassExtension on Widget {
  Widget wrapWithGlass() {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: this,
      ),
    );
  }
}

class _PokeBadge extends StatelessWidget {
  final String? partnerName;

  const _PokeBadge({this.partnerName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = partnerName == null || partnerName!.isEmpty
        ? l10n.nowPokeReceived
        : l10n.nowPokeReceivedFromName(partnerName!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 한국어 조사 을/를 판별 (받침 유무 기준)
/// 영어 등 다른 로케일에서는 공백만 반환 (조사 개념 없음)
String _particleEulReul(String text, [String locale = 'ko']) {
  if (!locale.startsWith('ko')) return ' ';
  if (text.isEmpty) return '를';
  final lastChar = text.codeUnitAt(text.length - 1);
  // 한글 유니코드 범위: 0xAC00 ~ 0xD7A3
  if (lastChar >= 0xAC00 && lastChar <= 0xD7A3) {
    return (lastChar - 0xAC00) % 28 == 0 ? '를' : '을';
  }
  return '를';
}
