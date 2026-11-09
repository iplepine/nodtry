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
import '../../together/application/together_providers.dart';
import '../../together/presentation/together_widgets.dart';
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
import '../../plan/presentation/widgets/plan_goal_label.dart';
import 'widgets/promise_proposal_sheet.dart';

part 'cards/card_shared.dart';
part 'cards/primary_executor_card.dart';
part 'cards/primary_executor_message.dart';
part 'cards/primary_executor_details.dart';
part 'cards/primary_executor_buttons.dart';
part 'cards/secondary_executor_card.dart';
part 'cards/manager_quick_card.dart';
part 'now_tab_parts/now_tab_record_actions.dart';
part 'now_tab_parts/now_tab_notification_handling.dart';
part 'now_tab_parts/now_tab_partner_actions.dart';
part 'now_tab_parts/now_tab_header_and_chips.dart';
part 'now_tab_parts/now_tab_fake_state_selector.dart';

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

/// '{planId}@{day}' for today — the key of [_NowTabState]'s cheered / knocked
/// sets. Top-level (it was a static on the state) so the part-file
/// extensions can call it unqualified.
String _todayKeyFor(String planId) {
  final now = DateTime.now();
  return '$planId@${now.year}-${now.month}-${now.day}';
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

  /// [setState] for the part-file extensions (now_tab_parts/): it is
  /// `@protected`, so only the state's own members may call it directly.
  void _setState(VoidCallback fn) => setState(fn);

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
                        // The partner's "같이 했어", waiting for my 나도 했어.
                        const TogetherClaimCards(),
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

}
