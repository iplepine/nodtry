import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';

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
      backgroundColor: AppColors.warmOffWhite,
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
                    text: 'Google로 시작하기',
                    onPressed: _handleGoogleLogin,
                    isLoading: _isGoogleLoading,
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Apple로 시작하기',
                    onPressed: _handleAppleLogin,
                    isLoading: _isAppleLoading,
                  ),
                ],
              ),

              // 하단: 신뢰 메시지
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  '강요하지 않아요. 기록은 둘만 봅니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
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

