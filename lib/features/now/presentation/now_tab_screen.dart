import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../models/plan_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/quiet_header.dart';
import '../../../widgets/time_chip.dart';
import '../../../models/home_state.dart';
import '../../../routes/app_router.dart';
import '../../../utils/time_formatter.dart';
import '../../../models/promise_model.dart';
import 'now_tab_intent.dart';
import 'now_tab_state.dart';
import 'now_tab_viewmodel.dart';
import 'now_tab_fake_states.dart';
import '../../../widgets/action_note_dialog.dart';
import '../../../services/notification_service.dart' as local_notifications;

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

  Future<void> _handleDidItForCard(
    HomeCardModel targetCard, {
    String? dialogTitle,
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

    final planTitle =
        targetCard.plan?.items.firstOrNull?.title ?? dialogTitle ?? '오늘 약속';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('오늘은 패스할까요?'),
        content: Text('$planTitle 약속을 오늘은 건너뜀으로 정리합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('오늘은 패스', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final skipped = await _skipCard(targetCard);
    if (!skipped || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('오늘 약속을 건너뛰었어요.')));
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
            const SnackBar(
              content: Text('시작을 응원해요!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('승인에 실패했어요.')));
        }
      }
    } else if (managerCard.state == HomeCardState.partnerAction) {
      // 실천 확인
      try {
        await ref
            .read(nowTabViewModelProvider.notifier)
            .dispatch(VerifyPartnerPlanIntent(planId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('실천을 확인했어요!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('확인 처리에 실패했어요.')));
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('조금 더 조율해볼까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRejectOption(context, '빈도를 조금 줄여보자'),
            const SizedBox(height: 8),
            _buildRejectOption(context, '다른 시간대가 좋을 것 같아'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(context, 'custom');
              },
              style: _rejectOptionStyle(),
              child: const Text('직접 입력하기'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
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
        ).showSnackBar(const SnackBar(content: Text('조율을 요청했어요')));
      }
    }
  }

  Future<String?> _showCustomRejectInput(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('어떤 점을 조율할까요?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '예: 주 3회로 시작해보는 건 어때?',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('보내기'),
          ),
        ],
      ),
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

    // 1. Random Reaction Selection
    final reactions = [
      ('🔥', '열정적인 응원을 보냈어요! 🔥'),
      ('❤️', '사랑을 담아 응원했어요! ❤️'),
      ('👍', '멋지다고 전했어요! 👍'),
      ('💪', '힘내라고 응원했어요! 💪'),
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
        ).showSnackBar(const SnackBar(content: Text('응원 전송에 실패했어요.')));
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
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            PokeUserIntent(
              model.partnerUid!,
              message: '똑똑! 약속을 기다리는 사람이 있어요. 오늘 약속을 만들어볼까요?',
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('똑똑 신호를 보냈어요.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('똑똑 전송에 실패했어요.')));
      }
    }
  }

  Future<void> _handlePokePartner(HomeCardModel model) async {
    if (model.plan?.id == null) return;
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(
            PokePartnerIntent(
              model.plan!.id!,
              message: '똑똑! 파트너가 기다리고 있어요. 지금 약속을 정리해볼까요?',
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('똑똑, 약속을 다시 당겼어요.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('똑똑 전송에 실패했어요.')));
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
    ).showSnackBar(const SnackBar(content: Text('4주 정산을 남겼어요.')));
  }

  Future<String?> _showPilotExitReasonDialog(BuildContext context) {
    final customController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('이번 4주는 여기서 멈출까요?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildExitReasonOption(context, '똑똑 압박이 약했어요'),
              const SizedBox(height: 8),
              _buildExitReasonOption(context, '목표가 너무 컸어요'),
              const SizedBox(height: 8),
              _buildExitReasonOption(context, '파트너 확인이 부담됐어요'),
              const SizedBox(height: 12),
              TextField(
                controller: customController,
                decoration: const InputDecoration(
                  labelText: '직접 입력',
                  hintText: '멈추는 이유를 짧게 남기기',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                customController.text.trim().isEmpty
                    ? '직접 사유 없음'
                    : customController.text.trim(),
              ),
              child: Text('남기기', style: TextStyle(color: AppColors.primary)),
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('휴식권 사용'),
        content: const Text('이번 주 1회 휴식권을 사용합니다.\n스트릭이 유지됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('사용하기', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _animationController.reverse();
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(RestPlanIntent(primaryCard!.plan!.id!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘은 편히 쉬세요. 스트릭은 유지됩니다!')),
        );
      }
    } catch (e) {
      if (mounted) {
        _animationController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('이미 사용')
                  ? '이번 주 휴식권을 이미 사용했어요.'
                  : '오류가 발생했습니다.',
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
          const SnackBar(content: Text('실천을 인정해줬어요! 스트릭이 유지됩니다.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('실천 인정에 실패했어요.')));
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

  void _handlePokeAck(HomeCardModel card) {
    if (card.plan?.id == null) return;
    ref
        .read(nowTabViewModelProvider.notifier)
        .dispatch(AcknowledgePokeIntent(card.plan!.id!));
  }

  Future<void> _handleRespondPromise(HomeCardModel card, bool accept) async {
    if (card.plan?.id == null) return;
    try {
      await ref
          .read(nowTabViewModelProvider.notifier)
          .dispatch(RespondPromiseIntent(card.plan!.id!, accept: accept));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? '약속을 수락했어요!' : '약속을 거절했어요.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('약속 응답에 실패했어요.')));
      }
    }
  }

  Future<void> _handleProposePromise(HomeCardModel card) async {
    if (card.plan?.id == null) return;

    final result =
        await showModalBottomSheet<
          ({PromiseReward? reward, PromisePenalty? penalty})
        >(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              const SafeArea(top: false, child: _PromiseProposalSheet()),
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
        ).showSnackBar(const SnackBar(content: Text('약속을 제안했어요!')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('약속 제안에 실패했어요.')));
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

          String suffix;
          if (diff.isNegative) {
            if (absDiff.inMinutes < 60) {
              suffix = '${absDiff.inMinutes}분 전 알림'; // "22:47 · 30분 전 알림"
            } else {
              suffix = '${absDiff.inHours}시간 전 알림';
            }
          } else {
            if (absDiff.inMinutes < 60) {
              suffix = '${absDiff.inMinutes}분 후 알림';
            } else {
              suffix = '${absDiff.inHours}시간 후 알림';
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
    } else if (text.contains('지남') || text == '어제' || text.endsWith('전')) {
      if (text.contains('지남') || text == '어제') return TimeChipType.past;
      if (text.contains('전')) return TimeChipType.upcoming;
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

    // 스트릭 기반 독려 메시지
    final streak = model.streakCount;
    if (streak != null && streak >= 5) {
      return '대단해요! 이 흐름을 이어가봐요';
    }

    // description에 if-then 패턴이 있으면 리마인더로 활용
    final desc = model.plan?.items.firstOrNull?.description;
    if (desc != null && desc.isNotEmpty) {
      if (desc.contains('하면') || desc.contains('되면') || desc.contains('나면')) {
        return desc;
      }
    }

    // if-then 팁 로테이션 (날짜 기반)
    final tips = [
      '"언제 할지" 정하면 실천 확률이 올라가요',
      '작게 시작해도 괜찮아요. 꾸준함이 힘이에요',
      '어제보다 나은 오늘이면 충분해요',
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
          String errorMessage = '알 수 없는 오류가 발생했습니다.';
          String? errorUrl;

          if (error.toString().contains('failed-precondition') ||
              error.toString().contains('requires an index')) {
            errorMessage = '데이터 조회에 필요한 인덱스가 없습니다.\n개발자에게 이 화면을 캡처해서 보내주세요.';

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
              title: const Text('오류 발생'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage),
                  if (errorUrl != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '생성 링크:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      errorUrl,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
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
                                      onSkip: _handleSkip,
                                      onRest: _handleRest,
                                      onCreatePlan: _handleCreatePlan,
                                      onModify: () => _handleModify(
                                        primaryExecutorCard,
                                      ), // Added
                                      onPokeAck: () => _handlePokeAck(
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
          if (kDebugMode)
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
              "잠시 후 다시 시도해주세요",
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
    final feedback = await showDialog<String>(
      context: context,
      builder: (context) => ActionNoteDialog(
        title: card.plan?.items.firstOrNull?.title ?? "파트너의 실천",
        hintText: "따뜻한 피드백을 남겨주세요 (선택)",
        buttonLabel: "확인하고 보내기",
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
          ).showSnackBar(const SnackBar(content: Text('응원 전송에 실패했어요.')));
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
    String selectedReaction = 'fire'; // Default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cheerSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Emoji Grid
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
                                alignment: Alignment.center,
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    // TextField
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
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    // Send Button
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
                                const SnackBar(content: Text('응원 전송에 실패했어요.')),
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
    );
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
  final VoidCallback? onSkip;
  final VoidCallback? onRest; // 휴식권
  final VoidCallback? onCreatePlan;
  final VoidCallback? onModify; // Added
  final VoidCallback? onPokeAck; // Added
  final VoidCallback? onAcceptPromise;
  final VoidCallback? onRejectPromise;
  final VoidCallback? onContinueAfterSettlement;
  final VoidCallback? onExitAfterSettlement;
  final String? timeChipText;
  final TimeChipType? timeChipType;
  final String? recordGazeText;
  final String? exactTimeText;

  const _PrimaryExecutorCard({
    required this.model,
    this.onDidIt,
    this.onSkip,
    this.onRest,
    this.onCreatePlan,
    this.onModify, // Added
    this.onPokeAck, // Added
    this.onAcceptPromise,
    this.onRejectPromise,
    this.onContinueAfterSettlement,
    this.onExitAfterSettlement,
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
              const SizedBox(height: 20),
              _buildButton(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, AppLocalizations l10n) {
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
            '${model.streakCount}회 연속 달성!',
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
          statusMessage = '조율이 필요해요'; // Fallback if headerMessage is null
          break;
        case HomeCardState.nextAction: // Type 1-3: 다음 일정
          // Next Action usually uses headerMessage or defaults to nothing special
          break;
        case HomeCardState.poked: // Type 1-8: 찌르기 받음
          statusMessage = '똑똑! 파트너가 기다리고 있어요';
          break;
        case HomeCardState.promiseProposed:
          statusMessage = '약속 제안이 도착했어요';
          break;
        case HomeCardState.promiseSettled:
          statusMessage = '약속 결과가 나왔어요';
          break;
        case HomeCardState.pilotSettlement:
          statusMessage = '4주 정산이 필요해요';
          subMessage = '똑똑이 실제로 약속을 당겼는지 확인하고 다음 4주를 정해요.';
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
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (model.plan?.lastCheerType != null) ...[
                Text(
                  model.plan!.lastCheerType!,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  model.plan!.lastComment!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
              Expanded(child: _buildSettlementMetric('완료', '$completed일')),
              Expanded(child: _buildSettlementMetric('파트너 반응', '$feedback회')),
              Expanded(child: _buildSettlementMetric('놓친 날', '$missed일')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completed >= 12
                ? '의미 있는 완료 기준인 12일을 넘겼어요. 다음 4주를 이어갈지 바로 정할 차례예요.'
                : '완주보다 중요한 건 어디서 끊겼는지 남기는 거예요. 다음 실험을 줄일 수 있게 사유를 남겨요.',
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
    final scheduledWeekdays = plan.items.expand((item) => item.days).toSet();
    if (scheduledWeekdays.isEmpty) {
      return plan.endDate.difference(plan.startDate).inDays + 1;
    }

    var count = 0;
    var day = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );
    while (!day.isAfter(end)) {
      if (scheduledWeekdays.contains(day.weekday)) count++;
      day = day.add(const Duration(days: 1));
    }
    return count;
  }

  int _partnerFeedbackCount(Plan plan) {
    var count = plan.verifiedDates.length + plan.rescuedDates.length;
    if (plan.lastCheerAt != null) count++;
    if (plan.lastPokeAt != null) count++;
    return count;
  }

  Widget _buildPromiseDetail(BuildContext context, Promise promise) {
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
                    '${promise.reward!.targetDays}일 성공 시: ${promise.reward!.description}',
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
                    '${promise.penalty!.targetDays}일 실패 시: ${promise.penalty!.description}',
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
              '성공 ${promise.settledSuccessDays}일 / 실패 ${promise.settledFailDays ?? 0}일',
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
        achieved ? (isReward ? '달성!' : '발동!') : '미달',
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
                  '거절',
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
                child: const Text(
                  '수락',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, AppLocalizations l10n) {
    final buttonTextColor = Colors.white;
    VoidCallback? onPressed;
    String buttonText;

    if (model.state == HomeCardState.poked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDidIt ?? onPokeAck,
              style: ElevatedButton.styleFrom(
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
              ),
              child: Text(
                '지금 처리하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: buttonTextColor,
                ),
              ),
            ),
          ),
          if (onPokeAck != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onPokeAck,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 32),
                padding: const EdgeInsets.symmetric(vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '똑똑 확인만 하기',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      );
    }

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
              child: const Text(
                '다음 4주 시작하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
            child: const Text(
              '이번 4주는 여기서 멈추기',
              style: TextStyle(
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    if (model.state == HomeCardState.nowAction) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.overdue) {
      buttonText = l10n.homeDidIt;
      onPressed = onDidIt;
    } else if (model.state == HomeCardState.emptyPlan) {
      buttonText = l10n.nowCreatePlan;
      onPressed = onCreatePlan;
    } else if (model.state == HomeCardState.rejected) {
      buttonText = '수정하기'; // "Modify"
      onPressed = onModify;
    } else if (model.state == HomeCardState.promiseProposed) {
      return _buildPromiseProposedButtons(context);
    } else if (model.state == HomeCardState.promiseSettled) {
      return const SizedBox.shrink();
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
              Text(
                l10n.nowAddMorePlan,
                style: const TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
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
        // 휴식권 버튼 (nowAction에서 사용 가능 시)
        if (model.state == HomeCardState.nowAction &&
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
            child: const Text(
              '오늘은 쉬어갈게요 (휴식권)',
              style: TextStyle(
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
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
              child: const Text(
                '오늘은 쉬어갈게요 (휴식권)',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
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
              child: Text(
                l10n.nowActionSkipToday,
                style: const TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
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
    final dateStr = '${now.month}.${now.day} (${_getWeekdayStr(now.weekday)})';

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
              title.isNotEmpty ? title : '지나간 약속',
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

  String _getWeekdayStr(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
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
                TextSpan(text: '${_particleEulReul(title ?? '')}\n'),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (model.plan?.lastCheerType != null) ...[
                    Text(
                      model.plan!.lastCheerType!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      model.plan!.lastComment!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    switch (model.state) {
      case HomeCardState.partnerAction:
        statusMessage = '확인 대기 · 응원 필요';
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
    this.timeChipText,
    this.timeChipType,
    this.exactTimeText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String headerText;
    if (model.state == HomeCardState.partnerAction) {
      headerText = '확인하고 당겨줄 차례';
    } else if (model.state == HomeCardState.partnerPlanCreate ||
        model.state == HomeCardState.partnerPlanModify) {
      if (model.headerMessage == '조정 중' ||
          model.headerMessage == '같이 맞춰보는 중이에요') {
        headerText = l10n.nowPartnerAdjusting;
      } else {
        headerText = l10n.nowPartnerProposed;
      }
    } else if (model.state == HomeCardState.partnerNoPlan) {
      headerText = '기다리는 중';
    } else if (model.state == HomeCardState.partnerPromiseProposed) {
      headerText = '약속 수락을 기다리는 중';
    } else if (model.state == HomeCardState.promiseSettled) {
      headerText = '약속 결과가 나왔어요';
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
            if (model.plan?.items.firstOrNull?.title != null) ...[
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
            if (model.plan != null)
              _buildPlanDetails(context, model.plan!, l10n),
            const SizedBox(height: 8),
            // Description (Diff Aware)
            if (model.plan?.items.firstOrNull?.description != null) ...[
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
            // Button (Only for partnerActionShare/partnerPlanShare that needs action)
            if (model.state == HomeCardState.partnerPlanCreate ||
                model.state == HomeCardState.partnerPlanModify) ...[
              if (model.headerMessage != '함께하는 중') ...[
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
                          "조율하기",
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
                        child: const Text(
                          "승인하기",
                          style: TextStyle(
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
                  '상대방이 아직 새로운 약속을 만들지 않았어요. 약속이 묻히기 전에 똑똑으로 불러볼까요?',
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
                  child: const Text(
                    "똑똑! 약속 만들라고 하기",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else if (model.state == HomeCardState.partnerPoke) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  model.headerMessage == '놓친 약속이 떴어요'
                      ? '${partnerName ?? "파트너"}님의 약속이 놓친 약속으로 남았어요. 똑똑으로 다시 당겨주세요.'
                      : '${partnerName ?? "파트너"}님의 약속이 아직 조용해요. 묻히기 전에 똑똑으로 당겨주세요.',
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
                  child: const Text(
                    "똑똑! 당기기",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                        Text(
                          '어제 실천 인정해주기',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else if (model.state == HomeCardState.partnerAction) ...[
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
                  child: const Text(
                    "확인하고 응원 보내기",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '약속 걸기',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
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

  Widget _buildManagerPromiseDetail(BuildContext context, Promise promise) {
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
              '🏆 ${promise.reward!.targetDays}일 성공 시: ${promise.reward!.description}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (promise.reward != null && promise.penalty != null)
            const SizedBox(height: 4),
          if (promise.penalty != null) ...[
            Text(
              '⚡ ${promise.penalty!.targetDays}일 실패 시: ${promise.penalty!.description}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          if (isSettled && promise.settledSuccessDays != null) ...[
            const SizedBox(height: 8),
            Text(
              '결과: 성공 ${promise.settledSuccessDays}일 / 실패 ${promise.settledFailDays ?? 0}일',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (promise.settlementResult != null) ...[
              const SizedBox(height: 4),
              Text(
                _settlementResultText(promise.settlementResult!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '수락 대기 중...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _settlementResultText(SettlementResult result) {
    switch (result) {
      case SettlementResult.rewardAchieved:
        return '🎉 보상 달성!';
      case SettlementResult.penaltyTriggered:
        return '⚡ 벌칙 발동!';
      case SettlementResult.bothMet:
        return '🎉 보상 달성! + ⚡ 벌칙 발동!';
      case SettlementResult.neitherMet:
        return '조건 미달';
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

class _PromiseProposalSheet extends StatefulWidget {
  const _PromiseProposalSheet();

  @override
  State<_PromiseProposalSheet> createState() => _PromiseProposalSheetState();
}

class _PromiseProposalSheetState extends State<_PromiseProposalSheet> {
  bool _enableReward = true;
  bool _enablePenalty = false;
  final _rewardDescController = TextEditingController();
  final _penaltyDescController = TextEditingController();
  int _rewardDays = 20;
  int _penaltyDays = 10;

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
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
              '약속 걸기',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '상대가 수락하면 약속이 시작돼요',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // 보상 섹션
            _buildSectionToggle(
              title: '🏆 보상 (당근)',
              enabled: _enableReward,
              onToggle: (v) => setState(() => _enableReward = v),
            ),
            if (_enableReward) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _rewardDescController,
                decoration: InputDecoration(
                  hintText: '예: 치킨 사주기, 맛집 가기',
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
                label: '성공 목표',
                days: _rewardDays,
                onChanged: (d) => setState(() => _rewardDays = d),
              ),
            ],

            const SizedBox(height: 16),

            // 벌칙 섹션
            _buildSectionToggle(
              title: '⚡ 벌칙 (채찍)',
              enabled: _enablePenalty,
              onToggle: (v) => setState(() => _enablePenalty = v),
            ),
            if (_enablePenalty) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _penaltyDescController,
                decoration: InputDecoration(
                  hintText: '예: 설거지 일주일, 커피 쏘기',
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
                label: '실패 한도',
                days: _penaltyDays,
                onChanged: (d) => setState(() => _penaltyDays = d),
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabled,
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '약속 제안하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    required ValueChanged<int> onChanged,
  }) {
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
            '$days일',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(days + 1),
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: AppColors.primary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

/// 한국어 조사 을/를 판별 (받침 유무 기준)
String _particleEulReul(String text) {
  if (text.isEmpty) return '를';
  final lastChar = text.codeUnitAt(text.length - 1);
  // 한글 유니코드 범위: 0xAC00 ~ 0xD7A3
  if (lastChar >= 0xAC00 && lastChar <= 0xD7A3) {
    return (lastChar - 0xAC00) % 28 == 0 ? '를' : '을';
  }
  return '를';
}
