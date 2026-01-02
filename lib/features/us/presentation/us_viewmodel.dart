import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'us_state.dart';
import '../../../providers/repository_provider.dart';

class UsViewModel extends AsyncNotifier<UsState> {
  @override
  FutureOr<UsState> build() async {
    // Listen to profile updates
    ref.listen(myProfileProvider, (prev, next) {
      if (next is AsyncData) {
        state = AsyncValue.data(state.value!.copyWith(myProfile: next.value));
      }
    });

    // Listen to connected profiles
    ref.listen(connectedProfilesProvider, (prev, next) {
      if (next is AsyncData) {
        state = AsyncValue.data(
          state.value!.copyWith(connectedProfiles: next.value ?? []),
        );
      }
    });

    return UsState(
      myProfile: ref.read(myProfileProvider).value,
      connectedProfiles: ref.read(connectedProfilesProvider).value ?? [],
    );
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
      } else if (intent is DisconnectIntent) {
        await _disconnect(intent.partnerId);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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

  Future<void> _disconnect(String partnerId) async {
    final useCase = ref.read(disconnectConnectionUseCaseProvider);
    await useCase.execute(partnerId);
    ref.invalidate(connectedProfilesProvider);
  }
}

final usViewModelProvider = AsyncNotifierProvider<UsViewModel, UsState>(
  () => UsViewModel(),
);
