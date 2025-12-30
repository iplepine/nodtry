import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../routes/app_router.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../providers/repository_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ... (Animation controllers kept same)
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _messageSlideAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _buttonFadeAnimation;

  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // ... (Animation definitions kept same - omitting for brevity as they are unchanged)
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

    // 자동 로그인 시도
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuthAndNavigate();
      }
    });
  }

  final AuthService _authService = AuthService();

  Future<void> _checkAuthAndNavigate() async {
    final user = _authService.currentUser;
    if (user != null) {
      // User Repository를 통해 초기화
      final repository = ref.read(userRepositoryProvider);
      await repository.initializeUser(user);
      _navigateToNext();
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      if (Platform.isAndroid) {
        final result = await _authService.signInWithGoogle();
        if (result != null && mounted) {
          final repository = ref.read(userRepositoryProvider);
          await repository.initializeUser(result.user!);
          _navigateToNext();
        }
      }
    } catch (e) {
      debugPrint('Google login failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isGuestLoading = true;
    });

    try {
      await ref.read(guestLoginUseCaseProvider).execute();

      if (mounted) {
        _navigateToNext();
      }
    } catch (e) {
      debugPrint('Guest login failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  void _navigateToNext() {
    // TODO: 커플 연결 여부 확인 후 적절한 화면으로 이동
    // 로그인/스플래시 -> 홈 or 연결 화면
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              SlideTransition(
                position: _buttonSlideAnimation,
                child: FadeTransition(
                  opacity: _buttonFadeAnimation,
                  child: Column(
                    children: [
                      // Android에서만 구글 로그인 버튼 표시
                      if (Platform.isAndroid) ...[
                        PrimaryButton(
                          text: AppLocalizations.of(context)!.loginWithGoogle,
                          onPressed: _handleGoogleLogin,
                          isLoading: _isGoogleLoading,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 게스트 로그인 (둘러보기) - OutlinedButton 스타일 적용
                      // 게스트 로그인 (둘러보기) - OutlinedButton 스타일 적용
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isGuestLoading ? null : _handleGuestLogin,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isGuestLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.loginGuest,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // 개발자 화면으로 이동
                      OutlinedButton(
                        onPressed: () {
                          context.go(AppRoutes.developer);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '🛠️ 개발자 화면',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
