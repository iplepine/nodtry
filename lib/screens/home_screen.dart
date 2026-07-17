import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../features/now/presentation/now_tab_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/us/presentation/screens/us_screen.dart';
import '../providers/notification_permission_provider.dart';
import '../widgets/notification_permission_banner.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check notification permission when the app returns to the foreground
    // (e.g. after the user toggles it in OS settings).
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationPermissionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
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
