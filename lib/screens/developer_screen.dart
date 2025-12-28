import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../routes/app_router.dart';

/// 개발자 화면 - 모든 화면으로 이동할 수 있는 디버그 화면
class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '개발자 화면',
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
                '화면 이동',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '각 화면으로 바로 이동할 수 있습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 32),

              // 화면 목록
              _buildScreenSection(
                context,
                title: '인증 & 연결',
                screens: [
                  _ScreenInfo(
                    name: '스플래시',
                    route: AppRoutes.splash,
                    description: '앱 시작 화면',
                    icon: Icons.rocket_launch,
                  ),
                  _ScreenInfo(
                    name: '로그인',
                    route: AppRoutes.login,
                    description: 'Google/Apple 로그인',
                    icon: Icons.login,
                  ),
                  _ScreenInfo(
                    name: '연결',
                    route: AppRoutes.connect,
                    description: '커플 연결 화면',
                    icon: Icons.link,
                  ),
                ],
              ),
              SizedBox(height: 32),

              _buildScreenSection(
                context,
                title: '메인 화면',
                screens: [
                  _ScreenInfo(
                    name: '홈',
                    route: AppRoutes.home,
                    description: '지금/기록/우리 탭',
                    icon: Icons.home,
                  ),
                ],
              ),
              SizedBox(height: 32),

              // 딥링크 섹션
              Divider(height: 32),
              Text(
                '딥링크',
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
                      '딥링크 URL 형식:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDeepLinkItem('스플래시', 'onmybehalf://splash'),
                    _buildDeepLinkItem('로그인', 'onmybehalf://login'),
                    _buildDeepLinkItem('연결', 'onmybehalf://connect'),
                    _buildDeepLinkItem('홈', 'onmybehalf://home'),
                    _buildDeepLinkItem('개발자', 'onmybehalf://developer'),
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
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(screen.route),
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
                  child: Icon(
                    screen.icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
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
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textDisabled,
                ),
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

