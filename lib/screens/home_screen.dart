import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../features/now/presentation/now_tab_screen.dart';
import 'tabs/history_tab.dart';
import 'tabs/us_tab.dart';

/// 홈 화면 - 하단 탭 구조
///
/// 3개 탭: 지금 · 기록 · 우리
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/repository_provider.dart';
import '../routes/app_router.dart';

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

    // 실시간 계정 삭제 모니터링
    ref.listen(myProfileProvider, (previous, next) {
      if (next is AsyncData && next.value == null) {
        // 계정이 삭제되었거나 로그아웃 됨
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;

          // 로그아웃 처리
          final authService = ref.read(authServiceProvider);
          await authService.signOut();

          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('계정 정보를 찾을 수 없습니다.')));
            context.go(AppRoutes.splash);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: IndexedStack(
        index: _currentIndex,
        children: const [NowTab(), HistoryTab(), UsTab()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
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
              fontWeight: FontWeight.w500,
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
    );
  }
}
