import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// removed unused firebase_auth import
import '../../../../l10n/app_localizations.dart';
import '../../../../routes/app_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_underlined_text.dart';
import '../../../../widgets/primary_button.dart';
import '../../../../providers/repository_provider.dart';
import '../auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true; // true: Login, false: SignUp

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLoginMode) {
      ref
          .read(authViewModelProvider.notifier)
          .dispatch(
            LoginWithEmailIntent(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    } else {
      ref
          .read(authViewModelProvider.notifier)
          .dispatch(
            SignUpWithEmailIntent(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  // _mapFirebaseError removed as it is now handled in AuthViewModel or not used directly here.

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState =
        ref.watch(authViewModelProvider).value ?? const AuthState();

    // Listen to profile updates for navigation
    ref.listen(myProfileProvider, (prev, next) {
      if (next is AsyncData && next.value != null) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Headline
                Text(
                  _isLoginMode ? l10n.login : l10n.signUp,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailHint;
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordHint;
                    }
                    if (value.length < 6) {
                      return l10n.weakPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Error Message
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Action Button
                PrimaryButton(
                  text: _isLoginMode ? l10n.login : l10n.signUp,
                  onPressed: _submit,
                  isLoading: authState.isEmailLoading,
                ),
                const SizedBox(height: 24),

                // Toggle Mode Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      ref
                          .read(authViewModelProvider.notifier)
                          .dispatch(const ClearErrorIntent());
                      _formKey.currentState?.reset();
                    });
                  },
                  child: AppUnderlinedText(
                    _isLoginMode ? l10n.emailLoginToggleSignUp : l10n.emailLoginToggleLogin,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
