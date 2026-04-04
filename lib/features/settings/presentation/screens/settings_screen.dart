import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_state.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme_enum.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routes/app_router.dart';
import '../../../../providers/repository_provider.dart';

/// 설정 화면 - 언어 및 테마 변경
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState =
        ref.watch(settingsViewModelProvider).value ??
        SettingsState(
          currentLocale: const Locale('ko', ''),
          currentTheme: AppThemeType.smokyPlum,
        );

    // 연결 끊기 성공 시 토스트 처리 등 (Listen)
    ref.listen(settingsViewModelProvider, (previous, next) {
      if (previous?.value?.isWithdrawing == true &&
          next.value?.isWithdrawing == false) {
        if (next.value?.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settingsAccountDeletedSuccess)),
          );
          context.go(AppRoutes.splash);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.settingsDeleteAccountFailed(next.value!.errorMessage!),
              ),
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 언어 설정
              Text(
                l10n.settingsLanguage,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                context,
                l10n.settingsLanguageKorean,
                const Locale('ko', ''),
                settingsState.currentLocale,
                () => ref
                    .read(settingsViewModelProvider.notifier)
                    .dispatch(const ChangeLocaleIntent(Locale('ko', ''))),
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                l10n.settingsLanguageEnglish,
                const Locale('en', ''),
                settingsState.currentLocale,
                () => ref
                    .read(settingsViewModelProvider.notifier)
                    .dispatch(const ChangeLocaleIntent(Locale('en', ''))),
              ),
              const SizedBox(height: 32),

              // 테마 설정
              Text(
                l10n.settingsTheme,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                l10n.settingsThemeSmokyPlum,
                AppThemeType.smokyPlum,
                settingsState.currentTheme,
                () => ref
                    .read(settingsViewModelProvider.notifier)
                    .dispatch(const ChangeThemeIntent(AppThemeType.smokyPlum)),
              ),
              const SizedBox(height: 12),
              _buildThemeOption(
                context,
                l10n.settingsThemeDeepOlive,
                AppThemeType.deepOlive,
                settingsState.currentTheme,
                () => ref
                    .read(settingsViewModelProvider.notifier)
                    .dispatch(const ChangeThemeIntent(AppThemeType.deepOlive)),
              ),
              const SizedBox(height: 32),

              if (kDebugMode) ...[
                // 개발자 옵션
                Text(
                  l10n.settingsDeveloper,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDeveloperOption(context),
                const SizedBox(height: 32),
              ],

              // 알림 설정 (New)
              _buildNotificationSettingsOption(context),
              const SizedBox(height: 32),

              // 지원 (New)
              Text(
                '지원', // l10n.settingsSupport (Need to add to l10n later, hardcode for now or generic)
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildDonationOption(context, ref),
              const SizedBox(height: 32),

              // 계정 관리
              Text(
                l10n.settingsAccount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildLogoutOption(context),
              const SizedBox(height: 12),
              _buildWithdrawOption(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsOption(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.pushNamed('notification-settings');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.settingsNotifications, // '알림 설정'
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
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

  Widget _buildLogoutOption(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsLogout,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsLogoutDesc,
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

  Future<void> _showLogoutDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLogoutDialogTitle),
        content: Text(l10n.settingsLogoutDialogContent),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              l10n.settingsLogoutConfirm,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref
          .read(settingsViewModelProvider.notifier)
          .dispatch(const LogoutIntent());
    }
  }

  Widget _buildWithdrawOption(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showWithdrawDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsDeleteAccount,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsDeleteAccountDesc,
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

  Future<void> _showWithdrawDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountDialogTitle),
        content: Text(l10n.settingsDeleteAccountDialogContent),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              l10n.settingsDelete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref
          .read(settingsViewModelProvider.notifier)
          .dispatch(const WithdrawAccountIntent());
    }
  }

  Widget _buildDeveloperOption(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.developer);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsDeveloper,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsDeveloperDesc,
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

  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    Locale locale,
    Locale currentLocale,
    VoidCallback onTap,
  ) {
    final isSelected = locale.languageCode == currentLocale.languageCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    AppThemeType theme,
    AppThemeType currentTheme,
    VoidCallback onTap,
  ) {
    final isSelected = theme == currentTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationOption(BuildContext context, WidgetRef ref) {
    // Watch IAP State
    final iapState = ref.watch(iapServiceProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!iapState.isAvailable) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('스토어와 연결할 수 없어요. (설정 확인 필요)')),
            );
            return;
          }
          if (iapState.isPurchasing) return;

          // Call notifier method
          await ref.read(iapServiceProvider.notifier).buyCoffee();

          if (iapState.purchaseError != null && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(iapState.purchaseError!)));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('☕', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '개발자에게 커피 사주기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (iapState.isPurchasing)
                        Text(
                          '결제 처리 중...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        Text(
                          '따뜻한 커피 한 잔이 큰 힘이 됩니다!',
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
}
