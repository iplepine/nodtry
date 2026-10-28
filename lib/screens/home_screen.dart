import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../features/now/presentation/now_tab_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/us/presentation/screens/us_screen.dart';
import '../providers/notification_permission_provider.dart';
import '../providers/repository_provider.dart';
import '../features/connect/application/partner_label_provider.dart';
import '../features/onboarding/presentation/home_prompts.dart';
import '../features/duo/application/duo_stats_provider.dart';
import '../features/now/application/notification_routing.dart';
import '../core/services/notification_service.dart';
import '../routes/app_router.dart';
import '../services/notification_service.dart' as local_notifications;
import '../widgets/notification_permission_banner.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

/// 홈 화면 - 하단 탭 구조
///
/// 3개 탭: 지금 · 기록 · 우리
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

/// 홈 화면 - 하단 탭 구조
///
/// 3개 탭: 지금 · 기록 · 우리
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _promptRunning = false;
  StreamSubscription<local_notifications.NotificationOpenRequest>?
  _openSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPrompts());

    // Opened notifications (foreground taps, background/cold-start pushes)
    // land here and go to the screen they are about.
    final notifications = local_notifications.NotificationService();
    _openSubscription = notifications.openRequests.listen(_routeOpened);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = notifications.takePendingOpenRequest();
      if (pending != null) _routeOpened(pending);
    });
  }

  /// Takes an opened notification to its screen (see
  /// [notificationOpenTargetForRequest]) and the promise it is about.
  void _routeOpened(local_notifications.NotificationOpenRequest request) {
    if (!mounted) return;
    final target = notificationOpenTargetForRequest(request);
    if (target == NotificationOpenTarget.none) return;

    final router = GoRouter.maybeOf(context);
    if (target == NotificationOpenTarget.connect) {
      router?.push(
        AppRoutes.connectEntry(failureReason: request.reason ?? 'unknown'),
      );
      return;
    }

    _backToTabs();
    final index = switch (target) {
      NotificationOpenTarget.history => 1,
      NotificationOpenTarget.us => 2,
      _ => 0,
    };
    if (index != _currentIndex) setState(() => _currentIndex = index);

    switch (target) {
      case NotificationOpenTarget.nowCheckIn:
        ref
            .read(nowFocusRequestProvider.notifier)
            .request(
              request.planId,
              checkIn: true,
              quickAction: request.quickAction,
            );
      case NotificationOpenTarget.now:
        // The promise's card (a partner's record, a 인정, a proposal …); one
        // that isn't on today's cards is looked for on 기록.
        if (request.planId != null) {
          ref
              .read(nowFocusRequestProvider.notifier)
              .request(
                request.planId,
                actionId: request.actionId,
                day: request.actionDate,
                quickAction: request.quickAction,
              );
        }
      case NotificationOpenTarget.history:
        ref
            .read(historyFocusRequestProvider.notifier)
            .request(
              request.planId,
              actionId: request.actionId,
              day: request.actionDate,
            );
      case NotificationOpenTarget.us:
        // A new partner: the nickname sheet comes from the home prompts.
        _schedulePrompts();
      default:
        break;
    }
  }

  /// Closes whatever is on top of the tabs: pushed screens (plan detail …)
  /// and the sheets / dialogs open on home itself — the promise would
  /// otherwise be focused under them.
  void _backToTabs() {
    final homeRoute = ModalRoute.of(context);
    if (homeRoute == null || homeRoute.isCurrent) return;
    Navigator.of(
      context,
    ).popUntil((route) => route == homeRoute || route.isFirst);
  }

  /// Rename notice / first-login clipboard look / nickname sheet — at most
  /// one at a time, and only while home is the route on top (the connect
  /// screen runs its own nickname offer).
  Future<void> _runPrompts() async {
    if (_promptRunning || !mounted) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _promptRunning = true;
    try {
      await runHomePrompts(context, ref);
    } finally {
      _promptRunning = false;
    }
  }

  void _schedulePrompts() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPrompts());
  }

  @override
  void dispose() {
    _openSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check notification permission when the app returns to the foreground
    // (e.g. after the user toggles it in OS settings).
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationPermissionProvider);
      // Permission turned on in Settings: register the push token now, not
      // at the next cold start.
      try {
        unawaited(ref.read(notificationServiceProvider).maybeRegister());
      } catch (_) {}
      // A new day while in the background: the duo header's "today".
      ref.read(duoTodayProvider.notifier).refresh();
      _schedulePrompts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // A promise to show on 기록 — from a notification, or handed over by the
    // Now tab when it isn't on today's cards.
    ref.listen(historyFocusRequestProvider, (previous, next) {
      if (next != null && _currentIndex != 1) {
        setState(() => _currentIndex = 1);
      }
    });

    // A partner appearing (or the profile loading) can make a prompt due.
    ref.listen(partnerLabelProvider, (previous, next) {
      if (previous?.partnerUid != next.partnerUid) _schedulePrompts();
    });
    ref.listen(myProfileProvider.select((p) => p.value?.uid), (previous, next) {
      if (next != null && previous != next) _schedulePrompts();
    });
    // Today turning into a 둘운완 day (or a new 인정) can make the share card
    // or the review request due.
    ref.listen(
      duoStatsProvider.select(
        (s) => s == null ? null : (s.todayIsDuoDone, s.streak),
      ),
      (previous, next) {
        if (next != null && previous != next) _schedulePrompts();
      },
    );
    ref.listen(
      myDuoPlansProvider.select(
        (plans) => plans == null ? null : countVerificationsReceived(plans),
      ),
      (previous, next) {
        if (next != null && previous != next) _schedulePrompts();
      },
    );

    // When the banner is shown it consumes the top safe area itself, so strip
    // the tabs' top inset to avoid a double gap below it.
    final notificationsOff =
        ref.watch(notificationPermissionProvider).value == false;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          const NotificationPermissionBanner(),
          Expanded(
            child: notificationsOff
                ? MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: _buildTabStack(),
                  )
                : _buildTabStack(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              top: false,
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  backgroundColor: Colors.transparent,
                  indicatorColor: AppColors.primary.withValues(alpha: 0.15),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  height: 68,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.bolt_outlined),
                      selectedIcon: const Icon(Icons.bolt),
                      label: l10n.tabNow,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.history_outlined),
                      selectedIcon: const Icon(Icons.history),
                      label: l10n.tabHistory,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.favorite_outline),
                      selectedIcon: const Icon(Icons.favorite),
                      label: l10n.tabUs,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabStack() {
    return IndexedStack(
      index: _currentIndex,
      children: const [NowTab(), HistoryScreen(), UsScreen()],
    );
  }
}
