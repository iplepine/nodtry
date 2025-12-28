import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../routes/app_router.dart';
import '../l10n/app_localizations.dart';

/// 개발자 화면 - 모든 화면으로 이동할 수 있는 디버그 화면
class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.developerTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Text(
                l10n.developerScreenNavigation,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                l10n.developerScreenNavigationDesc,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              SizedBox(height: 32),

              // 메인 화면 섹션
              _buildScreenSection(
                context,
                title: l10n.developerMainSection,
                screens: [
                  _ScreenInfo(
                    name: l10n.developerScreenHome,
                    route: AppRoutes.home,
                    description: l10n.developerScreenHomeDesc,
                    icon: Icons.home,
                  ),
                  _ScreenInfo(
                    name: l10n.developerScreenSettings,
                    route: AppRoutes.settings,
                    description: l10n.developerScreenSettingsDesc,
                    icon: Icons.settings,
                  ),
                ],
              ),
              SizedBox(height: 32),
              // 계획 생성 섹션
              _buildScreenSection(
                context,
                title: l10n.developerPlanSection,
                screens: [
                  _ScreenInfo(
                    name: l10n.developerScreenActionSelection,
                    route: AppRoutes.planActionSelection,
                    description: l10n.developerScreenActionSelectionDesc,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
              SizedBox(height: 32),

              // 인증 & 연결 섹션
              _buildScreenSection(
                context,
                title: l10n.developerAuthSection,
                screens: [
                  _ScreenInfo(
                    name: l10n.developerScreenSplash,
                    route: AppRoutes.splash,
                    description: l10n.developerScreenSplashDesc,
                    icon: Icons.rocket_launch,
                  ),
                  _ScreenInfo(
                    name: l10n.developerScreenLogin,
                    route: AppRoutes.login,
                    description: l10n.developerScreenLoginDesc,
                    icon: Icons.login,
                  ),
                  _ScreenInfo(
                    name: l10n.developerScreenConnect,
                    route: AppRoutes.connect,
                    description: l10n.developerScreenConnectDesc,
                    icon: Icons.link,
                  ),
                ],
              ),
              SizedBox(height: 32),

              // 딥링크 섹션
              Divider(height: 32),
              Text(
                l10n.developerDeepLink,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.developerDeepLinkFormat,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDeepLinkItem(
                      l10n.developerScreenSplash,
                      'onmybehalf://splash',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenLogin,
                      'onmybehalf://login',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenConnect,
                      'onmybehalf://connect',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenHome,
                      'onmybehalf://home',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenDeveloper,
                      'onmybehalf://developer',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenSettings,
                      'onmybehalf://settings',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenSection(
    BuildContext context, {
    required String title,
    required List<_ScreenInfo> screens,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        ...screens.map((screen) => _buildScreenCard(context, screen)),
      ],
    );
  }

  Widget _buildScreenCard(BuildContext context, _ScreenInfo screen) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(screen.route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(screen.icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        screen.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        screen.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeepLinkItem(String name, String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                SelectableText(
                  url,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 화면 정보 모델
class _ScreenInfo {
  final String name;
  final String route;
  final String description;
  final IconData icon;

  _ScreenInfo({
    required this.name,
    required this.route,
    required this.description,
    required this.icon,
  });
}
