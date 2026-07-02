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

// App Store Review rejected submission bd240493-bbc3-425f-a286-a8343a50f34f
// (May 23, 2026, Guideline 2.1(b)) because the in-app "buy the dev a coffee"
// IAP product (`donation_coffee`) had not been submitted alongside the binary
// in App Store Connect. Hide the entry point in shipped builds until the IAP
// is created + approved there; flip this to true and submit IAP metadata
// (incl. App Review screenshot) at the same time as the next release.
const bool _kShowCoffeeDonation = false;

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
        const SettingsState(currentTheme: AppThemeType.smokyPlum);
    // When the user hasn't explicitly chosen a language, resolve which chip to
    // highlight from the actual locale Flutter is rendering with.
    final effectiveLocale =
        settingsState.currentLocale ?? Localizations.localeOf(context);

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
                effectiveLocale,
                () => ref
                    .read(settingsViewModelProvider.notifier)
                    .dispatch(const ChangeLocaleIntent(Locale('ko', ''))),
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                l10n.settingsLanguageEnglish,
                const Locale('en', ''),
                effectiveLocale,
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
              ..._buildThemeOptions(
                context,
                ref,
                l10n,
                settingsState.currentTheme,
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
              _buildTutorialOption(context),
              const SizedBox(height: 12),
              _buildNotificationSettingsOption(context),
              const SizedBox(height: 32),

              // 지원 (Support) 섹션은 커피 후원 IAP가 App Store Connect에서
              // 승인된 뒤에만 표시한다. 미승인 상태에서 진입점을 노출하면
              // Apple Review가 Guideline 2.1(b)로 거부함.
              if (_kShowCoffeeDonation) ...[
                Text(
                  l10n.settingsSupport,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDonationOption(context, ref),
                const SizedBox(height: 32),
              ],

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

  Widget _buildTutorialOption(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.tutorial);
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
                        '앱 사용법',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '작은 약속을 만들고 확인받는 흐름을 다시 봅니다',
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
                ? AppColors.primary.withValues(alpha: 0.1)
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

  /// 모든 테마 옵션 리스트. 각 row 사이 12px 간격이 자동으로 들어간다.
  List<Widget> _buildThemeOptions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AppThemeType currentTheme,
  ) {
    final entries = <(AppThemeType, String)>[
      (AppThemeType.smokyPlum, l10n.settingsThemeSmokyPlum),
      (AppThemeType.deepOlive, l10n.settingsThemeDeepOlive),
      (AppThemeType.pacific, l10n.settingsThemePacific),
      (AppThemeType.roseMocha, l10n.settingsThemeRoseMocha),
      (AppThemeType.lavenderDusk, l10n.settingsThemeLavenderDusk),
    ];

    final widgets = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final (theme, label) = entries[i];
      if (i > 0) widgets.add(const SizedBox(height: 12));
      widgets.add(
        _buildThemeOption(
          context,
          label,
          theme,
          currentTheme,
          () => ref
              .read(settingsViewModelProvider.notifier)
              .dispatch(ChangeThemeIntent(theme)),
        ),
      );
    }
    return widgets;
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    AppThemeType theme,
    AppThemeType currentTheme,
    VoidCallback onTap,
  ) {
    final isSelected = theme == currentTheme;
    final palette = AppColors.paletteFor(theme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
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
                // primary/secondary 색 미리보기 — 사용자가 어떤 톤인지
                // 라벨만 보고 짐작하지 않아도 되도록.
                _ThemeSwatch(
                  primary: palette.primary,
                  secondary: palette.secondary,
                ),
                const SizedBox(width: 12),
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
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!iapState.isAvailable) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.settingsStoreUnavailable)),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                        l10n.settingsBuyDeveloperCoffee,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (iapState.isPurchasing)
                        Text(
                          l10n.settingsCoffeePurchasing,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        Text(
                          l10n.settingsCoffeeSubtitle,
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

/// 테마 선택 row 좌측에 띄우는 2-tone 색 미리보기.
///
/// primary가 좌측 ⅔ + secondary가 우측 ⅓로 살짝 겹친 원형 칩. 사용자가 라벨만
/// 보고 어떤 톤인지 모르는 일을 피하기 위함.
class _ThemeSwatch extends StatelessWidget {
  final Color primary;
  final Color secondary;

  const _ThemeSwatch({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // primary (큰 원)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          // secondary (살짝 겹친 원)
          Positioned(
            left: 14,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
