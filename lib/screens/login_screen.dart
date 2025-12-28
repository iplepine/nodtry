import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    // TODO: Google 로그인 로직 구현
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
      });
      // TODO: 로그인 성공 후 다음 화면으로 이동
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() {
      _isAppleLoading = true;
    });

    // TODO: Apple 로그인 로직 구현
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isAppleLoading = false;
      });
      // TODO: 로그인 성공 후 다음 화면으로 이동
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Warm Stone (#F4F1EE)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // 상단 여백
              const Spacer(flex: 2),

              // 중앙: 로그인 버튼
              Column(
                children: [
                  PrimaryButton(
                    text: AppLocalizations.of(context)!.loginWithGoogle,
                    onPressed: _handleGoogleLogin,
                    isLoading: _isGoogleLoading,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: AppLocalizations.of(context)!.loginWithApple,
                    onPressed: _handleAppleLogin,
                    isLoading: _isAppleLoading,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 게스트 로그인 (둘러보기)
              TextButton(
                onPressed: () {
                  // TODO: 실제 게스트 인증 처리 (Firebase Anonymous Auth)
                  // MVP 단계에서는 Auth 로직 없이 바로 홈으로 이동
                  context.go(AppRoutes.home);
                },
                child: Text(
                  AppLocalizations.of(context)!.loginGuest,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              // 하단: 신뢰 메시지 (Text Disabled)
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  AppLocalizations.of(context)!.privacyMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDisabled, // #B4ADB0
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
