import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routes/app_router.dart';
// Removed unused AuthService import
import '../../../../theme/app_colors.dart';
import '../../../../widgets/primary_button.dart';
import 'dart:io';

import '../../../../providers/repository_provider.dart';

import '../auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _messageSlideAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _messageSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _buttonSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // 시작하자마자 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(authViewModelProvider.notifier)
          .dispatch(const CheckAuthIntent());
    });
  }

  void _handleGoogleLogin() {
    ref
        .read(authViewModelProvider.notifier)
        .dispatch(const LoginWithGoogleIntent());
  }

  void _handleGuestLogin() {
    ref.read(authViewModelProvider.notifier).dispatch(const LoginGuestIntent());
  }

  void _navigateToNext() {
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState =
        ref.watch(authViewModelProvider).value ?? const AuthState();

    // Listen to profile updates for navigation
    ref.listen(myProfileProvider, (prev, next) {
      if (next is AsyncData && next.value != null) {
        _navigateToNext();
      }
    });

    // Listen to errors
    ref.listen(authViewModelProvider, (prev, next) {
      if (next is AsyncError ||
          (next is AsyncData && next.value?.errorMessage != null)) {
        final error = next is AsyncError
            ? next.error.toString()
            : next.value?.errorMessage;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 실패: $error')));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // 상단 여백
              const Spacer(flex: 2),

              // 메시지 영역 (위로 애니메이션)
              SlideTransition(
                position: _messageSlideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // 로고 영역
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 태그라인
                      Text(
                        AppLocalizations.of(context)!.splashTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // 중간 여백
              const Spacer(flex: 1),

              // 로그인 버튼 영역 (아래에서 애니메이션)
              SizedBox(
                height: 240,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: authState.isAutoLoggingIn
                      ? Column(
                          key: const ValueKey('loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              "로그인 중...",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : SlideTransition(
                          key: const ValueKey('buttons'),
                          position: _buttonSlideAnimation,
                          child: FadeTransition(
                            opacity: _buttonFadeAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Android에서만 구글 로그인 버튼 표시
                                if (Platform.isAndroid) ...[
                                  PrimaryButton(
                                    text: AppLocalizations.of(
                                      context,
                                    )!.loginWithGoogle,
                                    onPressed: _handleGoogleLogin,
                                    isLoading: authState.isGoogleLoading,
                                  ),
                                  const SizedBox(height: 12),

                                  // 이메일 로그인 버튼
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        context.push(AppRoutes.emailLogin);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.loginWithEmail,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // 게스트 로그인 (둘러보기) - 커스텀 밑줄 (Border)
                                TextButton(
                                  onPressed: authState.isGuestLoading
                                      ? null
                                      : _handleGuestLogin,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                  ),
                                  child: authState.isGuestLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.textSecondary,
                                                ),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.only(
                                            bottom: 0,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppColors.textSecondary,
                                                width: 1.0,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.loginGuest,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.textSecondary,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                ),

                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              // 하단: 신뢰 메시지
              const Spacer(flex: 2),
              SlideTransition(
                position: _buttonSlideAnimation,
                child: FadeTransition(
                  opacity: _buttonFadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      AppLocalizations.of(context)!.privacyMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
