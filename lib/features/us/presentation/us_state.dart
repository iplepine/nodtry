import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../models/user_model.dart';
import '../../../models/connected_user.dart';

part 'us_state.freezed.dart';

@freezed
abstract class UsState with _$UsState {
  const UsState._();
  const factory UsState({
    UserModel? myProfile,
    @Default([]) List<ConnectedUser> connectedProfiles,
    @Default(false) bool isLinking,
    @Default(false) bool isUpdatingProfile,
  }) = _UsState;
}

@freezed
class UsIntent with _$UsIntent {
  const factory UsIntent.refresh() = RefreshIntent;
  const factory UsIntent.updateProfile({
    String? displayName,
    String? statusMessage,
    String? profileImageUrl,
  }) = UpdateProfileIntent;
  const factory UsIntent.linkGoogle() = LinkGoogleIntent;
  const factory UsIntent.disconnect(String partnerId) = DisconnectIntent;
}
