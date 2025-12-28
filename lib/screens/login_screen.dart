import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      if (Platform.isAndroid) {
        // Android: Google Sign-In
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          if (googleAuth.accessToken != null && googleAuth.idToken != null) {
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );

            await FirebaseAuth.instance.signInWithCredential(credential);

            if (mounted) {
              context.go(AppRoutes.home);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Google login failed: $e');
      // TODO: 에러 처리
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
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
                  // Android에서만 구글 로그인 버튼 표시
                  if (Platform.isAndroid) ...[
                    PrimaryButton(
                      text: AppLocalizations.of(context)!.loginWithGoogle,
                      onPressed: _handleGoogleLogin,
                      isLoading: _isGoogleLoading,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // iOS에서는 애플 로그인을 넣어야 하지만, 게스트 모드만 제공하기 위해 숨김처리
                  // if (Platform.isIOS) ... [ Apple Login Button ]
                ],
              ),

              const SizedBox(height: 16),

              // 게스트 로그인 (둘러보기)
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInAnonymously();
                    if (context.mounted) {
                      context.go(AppRoutes.home);
                    }
                  } catch (e) {
                    debugPrint('Guest login failed: $e');
                    // TODO: 에러 처리 (스낵바 등)
                  }
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
