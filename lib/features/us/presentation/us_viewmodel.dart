import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'us_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/repository_provider.dart';

class UsViewModel extends AsyncNotifier<UsState> {
  @override
  @override
  FutureOr<UsState> build() async {
    // Watch providers directly to allow auto-rebuild on changes
    final myProfileAsync = ref.watch(myProfileProvider);
    final connectedProfilesAsync = ref.watch(connectedProfilesProvider);

    // If either is loading, we can return pre-existing state if implementing optimistic updates,
    // or let AsyncNotifier handle loading state naturally.
    // Here we'll return the combined state.

    final myProfile = myProfileAsync.value;
    final connectedProfiles = connectedProfilesAsync.value ?? [];

    return UsState(myProfile: myProfile, connectedProfiles: connectedProfiles);
  }

  Future<void> dispatch(UsIntent intent) async {
    if (!state.hasValue) return;

    try {
      if (intent is RefreshIntent) {
        ref.invalidate(myProfileProvider);
        ref.invalidate(connectedProfilesProvider);
      } else if (intent is UpdateProfileIntent) {
        await _updateProfile(intent);
      } else if (intent is LinkGoogleIntent) {
        await _linkGoogle();
      } else if (intent is LinkEmailIntent) {
        await _linkEmail(intent.email, intent.password);
      } else if (intent is DisconnectIntent) {
        await _disconnect(intent.partnerId);
      }
    } catch (e, stack) {
      if (intent is LinkGoogleIntent ||
          intent is UpdateProfileIntent ||
          intent is LinkEmailIntent) {
        // 액션 중 에러는 전체 상태를 에러로 바꾸지 않고 알림만 설정
        String errorMessage = e.toString();
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'credential-already-in-use':
              errorMessage = "이 계정은 이미 다른 사용자와 연결되어 있습니다.";
              break;
            case 'invalid-credential':
              errorMessage = "유효하지 않은 인증 정보입니다.";
              break;
            case 'operation-not-allowed':
              errorMessage = "허용되지 않은 작업입니다.";
              break;
            default:
              errorMessage = e.message ?? "계정 연동 중 오류가 발생했습니다.";
          }
        }
        state = AsyncValue.data(
          state.value!.copyWith(
            errorNotification: errorMessage,
            isLinking: false,
            isUpdatingProfile: false,
          ),
        );
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void clearError() {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(errorNotification: null));
    }
  }

  Future<void> _updateProfile(UpdateProfileIntent intent) async {
    state = AsyncValue.data(state.value!.copyWith(isUpdatingProfile: true));
    final useCase = ref.read(updateProfileUseCaseProvider);
    await useCase.execute(
      name: intent.displayName,
      statusMessage: intent.statusMessage,
      imagePath: intent.profileImageUrl,
    );
    state = AsyncValue.data(state.value!.copyWith(isUpdatingProfile: false));
  }

  Future<void> _linkGoogle() async {
    state = AsyncValue.data(state.value!.copyWith(isLinking: true));
    final useCase = ref.read(linkWithGoogleUseCaseProvider);
    await useCase.execute();
    state = AsyncValue.data(state.value!.copyWith(isLinking: false));
  }

  Future<void> _linkEmail(String email, String password) async {
    state = AsyncValue.data(state.value!.copyWith(isLinking: true));
    final useCase = ref.read(linkWithEmailUseCaseProvider);
    await useCase.execute(email, password);
    state = AsyncValue.data(state.value!.copyWith(isLinking: false));
  }

  Future<void> _disconnect(String partnerId) async {
    final useCase = ref.read(disconnectConnectionUseCaseProvider);
    await useCase.execute(partnerId);
    ref.invalidate(connectedProfilesProvider);
  }
}

final usViewModelProvider = AsyncNotifierProvider<UsViewModel, UsState>(
  () => UsViewModel(),
);
