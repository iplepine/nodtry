import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings_state.dart';
import '../../../../providers/app_settings_provider.dart';
import '../../../../providers/repository_provider.dart';
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
    state = AsyncValue.data(
      prevState.copyWith(isWithdrawing: true, errorMessage: null),
    );

    try {
      final withdrawUseCase = ref.read(withdrawUseCaseProvider);
      await withdrawUseCase.execute();
      state = AsyncValue.data(state.value!.copyWith(isWithdrawing: false));
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isWithdrawing: false, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      // 로그아웃 후 인증 상태를 완전히 초기화하여 잔상 제거
      ref.invalidate(authViewModelProvider);
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(errorMessage: e.toString()),
      );
    }
  }
}

