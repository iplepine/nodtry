import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'tabs/now_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/us_tab.dart';

/// 홈 화면 - 하단 탭 구조
///
/// 3개 탭: 지금 · 기록 · 우리
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: false,
      body: _buildCurrentTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const NowTab();
      case 1:
        return const HistoryTab();
      case 2:
        return const UsTab();
      default:
        return const NowTab();
    }
  }
}
