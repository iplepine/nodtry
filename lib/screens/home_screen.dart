import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../features/now/presentation/now_tab_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/us/presentation/screens/us_screen.dart';

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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: IndexedStack(
        index: _currentIndex,
        children: const [NowTab(), HistoryScreen(), UsScreen()],
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
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textDisabled,
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.today_outlined),
                    activeIcon: const Icon(Icons.today),
                    label: l10n.tabNow,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.history_outlined),
                    activeIcon: const Icon(Icons.history),
                    label: l10n.tabHistory,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.favorite_outline),
                    activeIcon: const Icon(Icons.favorite),
                    label: l10n.tabUs,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
