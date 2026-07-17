import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings_state.dart';
import '../../../../providers/app_settings_provider.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../utils/analytics.dart';
import '../../../../utils/error_reporter.dart';
import '../../../../utils/ui_error_codes.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsState>(
      SettingsViewModel.new,
    );

class SettingsViewModel extends AsyncNotifier<SettingsState> {
  @override
  FutureOr<SettingsState> build() {
    final settings = ref.watch(appSettingsProvider);
    return SettingsState(
      currentLocale: settings.currentLocale,
      currentTheme: settings.currentTheme,
    );
  }

  Future<void> dispatch(SettingsIntent intent) async {
    final prevState = state.value!;

    if (intent is ChangeLocaleIntent) {
      ref.read(appSettingsProvider.notifier).setLocale(intent.locale);
      state = AsyncValue.data(prevState.copyWith(currentLocale: intent.locale));
    } else if (intent is ChangeThemeIntent) {
      ref.read(appSettingsProvider.notifier).setTheme(intent.theme);
      state = AsyncValue.data(prevState.copyWith(currentTheme: intent.theme));
    } else if (intent is WithdrawAccountIntent) {
      await _withdraw();
    } else if (intent is LogoutIntent) {
      await _logout();
    }
  }

  Future<void> _withdraw() async {
    final prevState = state.value!;
    // Deleting an account is irreversible and the row stays on screen while it
    // runs, so a second tap must not start a second deletion.
    if (prevState.isWithdrawing) return;

    state = AsyncValue.data(
      prevState.copyWith(isWithdrawing: true, errorMessage: null),
    );

    try {
      final withdrawUseCase = ref.read(withdrawUseCaseProvider);
      await withdrawUseCase.execute();
      state = AsyncValue.data(state.value!.copyWith(isWithdrawing: false));
    } catch (e, stack) {
      ErrorReporter.record(e, stack, reason: 'withdrawAccount');
      // A code, not `e.toString()`: this used to put the raw exception in front
      // of the user. See utils/ui_error_codes.dart.
      state = AsyncValue.data(
        state.value!.copyWith(
          isWithdrawing: false,
          errorMessage: SettingsErrorCode.withdrawFailed,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      AnalyticsService.log(AnalyticsEvent.logout);
      // 로그아웃 후 인증 상태를 완전히 초기화하여 잔상 제거
      ref.invalidate(authViewModelProvider);
    } catch (e, stack) {
      ErrorReporter.record(e, stack, reason: 'logout');
      state = AsyncValue.data(
        state.value!.copyWith(errorMessage: SettingsErrorCode.logoutFailed),
      );
    }
  }
}

