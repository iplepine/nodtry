import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../models/plan_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_underlined_text.dart';
import '../../../widgets/notification_focus_frame.dart';
import '../../../widgets/quiet_header.dart';
import '../../../widgets/reaction_icon.dart';
import '../../../widgets/time_chip.dart';
import '../../../models/home_state.dart';
import '../../../routes/app_router.dart';
import '../../../utils/time_formatter.dart';
import '../../../utils/build_flags.dart';
import '../../../utils/error_reporter.dart';
import '../../../models/promise_model.dart';
import '../../../models/proof_photo.dart';
import '../../../repositories/record_repository.dart';
import '../../connect/application/partner_label_provider.dart';
import '../../connect/presentation/widgets/now_invite_card.dart';
import '../../duo/application/duo_stats_provider.dart';
import '../../duo/presentation/duo_widgets.dart';
import '../../../providers/repository_provider.dart';
import '../application/notification_routing.dart';
import '../../../services/notification_quick_actions.dart';
import '../application/poke_reply_store.dart';
import '../../plan/domain/workout_template.dart';
import '../../proof/domain/proof_analytics.dart';
import '../../proof/presentation/proof_capture.dart';
import '../../proof/presentation/proof_photo_view.dart';
import '../../proof/presentation/proof_reaction_row.dart';
import 'cards/check_in_question.dart';
import 'now_tab_intent.dart';
import 'now_tab_state.dart';
import 'now_tab_viewmodel.dart';
import 'now_tab_fake_states.dart';
import '../../../widgets/action_note_dialog.dart';
import '../../../services/notification_service.dart' as local_notifications;
import 'cards/now_card_rules.dart';
import 'focus_timer/focus_timer_picker.dart';
import 'focus_timer/focus_timer_screen.dart';
import 'promise/active_promise_chip.dart';
import 'widgets/promise_proposal_sheet.dart';

part 'cards/card_shared.dart';
part 'cards/primary_executor_card.dart';
part 'cards/secondary_executor_card.dart';
part 'cards/manager_quick_card.dart';

/// The focus timer is a study-era feature and is hidden for the workout
/// pivot. Its files, tests and the card wiring stay so it can come back.
const bool _kFocusTimerEnabled = false;

/// '어제 실천 인정해주기' (rescue) is hidden on the partner card. The intent,
/// repository method and handler stay; only the button is not offered.
const bool _kRescueButtonEnabled = false;

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

  /// An opened notification: bring its promise's card into view (with the
  /// check-in choices for a reminder / knock) once the cards are in.
  NotificationFocusRequest? _pendingFocus;
  bool _isHandlingCheckIn = false;

  /// Runs once the cards were in without [_pendingFocus]'s promise; when it
  /// is over, the promise is looked for elsewhere (see
  /// [notificationFocusGrace]).
  Timer? _pendingFocusGrace;
  bool _pendingFocusGraceOver = false;

  /// The card an opened notification is about, and a new token per focus
  /// (see [NotificationFocusFrame]).
  NowCardSpot? _focusedSpot;
  int _focusToken = 0;

  /// A record is being saved (photo upload, server ack): the faded cards
  /// take no taps and a spinner shows instead.
  bool _recording = false;

  /// Partner cards I already cheered / knocked from this session, as
  /// '{planId}@{day}' — the buttons turn off right away instead of waiting for
  /// the plan stream.
  final Set<String> _cheeredPlans = {};
  final Set<String> _knockedPlans = {};

  static String _todayKeyFor(String planId) {
    final now = DateTime.now();
    return '$planId@${now.year}-${now.month}-${now.day}';
  }

  /// Actions currently awaiting the network, keyed by intent + target.
  ///
  /// Nothing on a card disables itself while its handler is in flight, so a
  /// double tap used to fire the intent twice — two knocks meant the partner
  /// got two push notifications for one tap.
  final Set<String> _inFlightActions = {};

  // Primary 카드 캐러셀: 점 인디케이터 탭 / '넘기기' 버튼으로 오늘의 다른 실천을 순회한다.
  int _primaryActiveIndex = 0;
  String? _carouselSignature;

  /// true면 "아래에서 위로 솟는" 입장 애니메이션(첫 로드/새로고침용),
  /// false면 캐러셀 카드 이동용 페이드만. 카드 전환 시 새로고침처럼 보이지 않게 한다.
  bool _animateCarouselEntrance = true;

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

      final pendingFocus = ref.read(nowFocusRequestProvider);
      if (pendingFocus != null) _queueFocus(pendingFocus);
    });
  }

  @override
  void dispose() {
    _notificationInputSubscription?.cancel();
    _notificationSkipSubscription?.cancel();
    _pendingFocusGrace?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // 데이터 변경 감지 시 애니메이션 처리 (첫 로드/새로고침: 위로 솟는 입장 연출)
  void _onDataLoaded() {
    if (mounted) {
      _animateCarouselEntrance = true;
      _animationController.forward(from: 0.0);
    }
  }

  /// 점 인디케이터를 탭하면 해당 카드로 바로 이동한다.
  /// 카드 간 이동은 새로고침처럼 보이지 않게 페이드만 준다.
  void _goToCarouselIndex(int index, int count) {
    final next = index.clamp(0, count - 1);
    if (next == _primaryActiveIndex) return;
    setState(() {
      _primaryActiveIndex = next;
      _animateCarouselEntrance = false;
    });
    _animationController.forward(from: 0.0);
  }

  /// 카드를 좌우로 스와이프하면 캐러셀을 이전/다음 카드로 넘긴다.
  /// (왼쪽으로 밀기 = 다음 카드, 오른쪽으로 밀기 = 이전 카드)
  void _handleCarouselSwipe(DragEndDetails details, int count) {
    if (count <= 1) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return; // 미세한 드래그는 무시
    final delta = velocity < 0 ? 1 : -1;
    final next = (_primaryActiveIndex + delta).clamp(0, count - 1);
    _goToCarouselIndex(next, count);
  }

  /// 현재 캐러셀에서 스와이프로 선택된 카드. 비어있으면 기존 primaryCard 폴백.
  HomeCardModel? _activePrimaryCard() {
    final state = ref.read(nowTabViewModelProvider).value;
    if (state == null) return null;
    final carousel = state.primaryCarouselCards;
    if (carousel.isEmpty) return state.primaryCard;
    final idx = _primaryActiveIndex.clamp(0, carousel.length - 1);
    return carousel[idx];
  }

  String _carouselSignatureFor(List<HomeCardModel> cards) {
    return cards.map((c) => '${c.state.name}:${c.plan?.id ?? ""}').join('|');
  }

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

      if (note == null || !mounted) {
        // Canceled: Do nothing (card didn't vanish)
        return;
      }

      await _completeCard(targetCard, note: note);
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
      final note = await showProofPreviewSheet(
        context,
        upload: upload,
        title: card.plan?.items.firstOrNull?.title,
      );
      if (note == null || !mounted) return;
      await _completeCard(card, note: note, photo: upload);
    });
  }

  /// Plays the "done" animation and reports [targetCard], with [photo] when
  /// given. Tells the user when the record was saved without the photo.
  Future<void> _completeCard(
    HomeCardModel targetCard, {
    required String note,
    ProofPhotoUpload? photo,
  }) async {
    final planId = targetCard.plan?.id;
    if (planId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    // The cards fade out while the record is saved (an upload can take up to
    // 8 s): no taps on the invisible cards, and a spinner meanwhile.
    setState(() => _recording = true);

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
          .complete(CompletePlanIntent(planId, message: note, photo: photo));
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
        setState(() => _recording = false);
        // Bring the cards back even when the plan stream didn't emit.
        if (_animationController.status == AnimationStatus.dismissed) {
          _onDataLoaded();
        }
      }
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
    setState(() {
      _focusedSpot = spot;
      _focusToken++;
    });
    // Taken in by the frame on this build; a card that moves into that slot
    // later must not be focused.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _focusedSpot = null);
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
          setState(() => _knockedPlans.add(_todayKeyFor(model.plan!.id!)));
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
        if (mounted) setState(() => _cheeredPlans.add(_todayKeyFor(planId)));
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
        if (mounted) setState(() {});
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
        setState(() {
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

  @override
  Widget build(BuildContext context) {
    // Provider 구독
    final homeStateAsync = ref.watch(nowTabViewModelProvider);

    // An opened notification (routed here by the home screen).
    ref.listen(nowFocusRequestProvider, (previous, next) {
      if (next != null) _queueFocus(next);
    });

    // 데이터 변경 감지하여 애니메이션 트리거
    ref.listen(nowTabViewModelProvider, (previous, next) {
      if (!next.hasValue) return;

      if (_pendingFocus != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openPendingFocusIfReady();
        });
      }

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
        _carouselSignature = _carouselSignatureFor(
          next.value!.primaryCarouselCards,
        );
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
          ErrorReporter.record(
            error ?? 'unknown',
            next.stackTrace,
            reason: 'nowTabLoad',
          );
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
          }
          // Anything else keeps the localized fallback above — a raw
          // `error.toString()` here meant users read Firestore internals like
          // "[cloud_firestore/permission-denied] The caller does not have...".
          // The detail still reaches Crashlytics via ErrorReporter.

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

      // Primary 캐러셀 구성이 바뀌면 보던 카드(약속)에 머물고, 그 카드가
      // 빠졌으면 첫번째로 리셋한다. (알림으로 맞춰 둔 카드가 다음 스냅샷에
      // 첫 카드로 되돌아가지 않게.)
      final nextCarousel = nextUiState.primaryCarouselCards;
      final nextSignature = _carouselSignatureFor(nextCarousel);
      if (nextSignature != _carouselSignature) {
        final prevCarousel = prevUiState.primaryCarouselCards;
        String? activePlanId;
        if (prevCarousel.isNotEmpty) {
          final active = _primaryActiveIndex.clamp(0, prevCarousel.length - 1);
          activePlanId = prevCarousel[active].plan?.id;
        }
        final kept = activePlanId == null
            ? -1
            : nextCarousel.indexWhere((c) => c.plan?.id == activePlanId);
        if (mounted) {
          setState(() {
            _carouselSignature = nextSignature;
            _primaryActiveIndex = kept >= 0 ? kept : 0;
          });
        }
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
      final carouselCards = uiState.primaryCarouselCards;
      // 캐러셀에서 현재 선택된 카드. 없으면 기존 primaryCard 폴백.
      final HomeCardModel? primaryExecutorCard = carouselCards.isNotEmpty
          ? carouselCards[_primaryActiveIndex.clamp(
              0,
              carouselCards.length - 1,
            )]
          : uiState.primaryCard;
      final secondaryExecutorCards = uiState.secondaryCards;
      final managerCards = uiState.managerCards;
      _maybeAutoAcknowledgePoke(primaryExecutorCard);

      return Stack(
        children: [
          AbsorbPointer(
            // No taps on cards that are fading out while a record is saved.
            absorbing: _recording,
            child: Column(
            children: [
              // 헤더
              _buildHeader(uiState),
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
                        // No partner yet: invite first (hidden otherwise).
                        const NowInviteCard(),
                        // Executor Area (Primary Action)
                        if (primaryExecutorCard != null) ...[
                          FadeTransition(
                            opacity: _primaryFadeAnimation,
                            child: ScaleTransition(
                              // 카드 간 이동 시에는 스케일/슬라이드 없이 페이드만 줘서
                              // 새로고침처럼 "솟아오르는" 느낌을 없앤다.
                              scale: _animateCarouselEntrance
                                  ? _primaryScaleAnimation
                                  : const AlwaysStoppedAnimation<double>(1.0),
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: _animateCarouselEntrance
                                          ? const Offset(
                                              0,
                                              0.15,
                                            ) // 첫 로드/새로고침: 아래에서 위로
                                          : Offset.zero, // 카드 이동: 제자리
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
                                    child: NotificationFocusFrame(
                                      focusToken: _focusTokenFor(
                                        NowCardArea.carousel,
                                      ),
                                      child: _PrimaryExecutorCard(
                                        // 키를 부여해 스와이프 시 위젯 상태가 새 카드로 재구성되게 한다.
                                        key: ValueKey(
                                          '${primaryExecutorCard.state.name}:${primaryExecutorCard.plan?.id ?? ""}',
                                        ),
                                        model: primaryExecutorCard,
                                        onPokeReply: _pokeReplyFor(
                                          primaryExecutorCard,
                                        ),
                                        onDidIt: _handleDidIt,
                                        onProofPhoto: _handleProofPhoto,
                                        onFocusTimer: _kFocusTimerEnabled
                                            ? _handleFocusTimer
                                            : null,
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
                                        onDismissOptions: () =>
                                            _showActionDeferSheet(
                                              primaryExecutorCard,
                                            ),
                                        onTap: () =>
                                            _handleCardTap(primaryExecutorCard),
                                        onHorizontalSwipe:
                                            carouselCards.length > 1
                                            ? (details) => _handleCarouselSwipe(
                                                details,
                                                carouselCards.length,
                                              )
                                            : null,
                                        timeChipText: _getTimeChipText(
                                          primaryExecutorCard,
                                        ),
                                        timeChipType: _getTimeChipType(
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
                          ),
                          if (carouselCards.length > 1) ...[
                            const SizedBox(height: 8),
                            _PrimaryCarouselIndicator(
                              count: carouselCards.length,
                              activeIndex: _primaryActiveIndex.clamp(
                                0,
                                carouselCards.length - 1,
                              ),
                              onTap: (i) =>
                                  _goToCarouselIndex(i, carouselCards.length),
                            ),
                          ],
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
                          for (final (index, state)
                              in secondaryExecutorCards.indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: FadeTransition(
                                opacity: _secondaryFadeAnimation,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.85,
                                    child: NotificationFocusFrame(
                                      focusToken: _focusTokenFor(
                                        NowCardArea.secondary,
                                        index,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(16),
                                      ),
                                      child: _SecondaryExecutorCard(
                                        model: state,
                                        timeChipText: _getTimeChipText(state),
                                        timeChipType: _getTimeChipType(state),
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
                          for (final (index, card) in managerCards.indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FadeTransition(
                                opacity: _managerFadeAnimation,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.88,
                                    child: NotificationFocusFrame(
                                      focusToken: _focusTokenFor(
                                        NowCardArea.manager,
                                        index,
                                      ),
                                      child: _ManagerQuickCard(
                                        model: card,
                                        partnerName: card.partnerName,
                                        onApprove: () => _handleApprove(card),
                                        onReject: () => _handleReject(card),
                                        onReact: (emoji) =>
                                            _handleReact(card, emoji),
                                        onAddNote: () =>
                                            _handleReactWithNote(card),
                                        onPokeUser: () => _handlePokeUser(card),
                                        onPokePartner: () =>
                                            _handlePokePartner(card),
                                        onSendCheer: () => _handleSendCheer(card),
                                        cheerSent:
                                            card.plan?.id != null &&
                                            _cheeredPlans.contains(
                                              _todayKeyFor(card.plan!.id!),
                                            ),
                                        knockSent:
                                            knockedToday(
                                              card.plan,
                                              now: DateTime.now(),
                                            ) ||
                                            (card.plan?.id != null &&
                                                _knockedPlans.contains(
                                                  _todayKeyFor(card.plan!.id!),
                                                )),
                                        onRescue: _kRescueButtonEnabled
                                            ? () => _handleRescue(card)
                                            : null,
                                        onProposePromise: () =>
                                            _handleProposePromise(card),
                                        onAcknowledgePromiseSettled: () =>
                                            _handleAcknowledgePromiseSettled(
                                              card,
                                            ),
                                        timeChipText: _getTimeChipText(card),
                                        timeChipType: _getTimeChipType(card),
                                        exactTimeText: _getExactTimeText(card),
                                      ).wrapWithGlass(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
          if (_recording)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(
                    key: ValueKey('now-recording-progress'),
                  ),
                ),
              ),
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
