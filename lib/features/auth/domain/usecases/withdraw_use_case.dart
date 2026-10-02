import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../repositories/record_repository.dart';
import '../../../../repositories/connect_repository.dart';
import '../../../../services/auth_service.dart';
import '../../../../repositories/user_repository.dart';
import '../../../../datasources/user_local_data_source.dart';
import '../../../../usecases/cancel_all_notifications_use_case.dart';
import '../../../../utils/analytics.dart';

/// 회원 탈퇴.
///
/// The Auth account goes first, right after signing in again: the server's
/// `onAuthUserDeleted` then removes everything — plans, relations (the
/// partner is unlinked), actions, cheers, every `proofs/{uid}/` photo and the
/// user document — as the privacy policy promises. The old order deleted
/// Firestore data first and the account last; `user.delete()` then failed
/// with `requires-recent-login` for most sessions, the account survived, the
/// server cleanup never ran, and the proof photos stayed.
///
/// Throws [ReauthCancelledException] / [ReauthPasswordRequiredException]
/// before anything is deleted.
class WithdrawUseCase {
  final AuthService _authService;
  final UserRepository _userRepository;
  final UserLocalDataSource _userLocalDataSource;
  final RecordRepository _recordRepository;
  final ConnectRepository _connectRepository;
  final CancelAllNotificationsUseCase _cancelAllNotificationsUseCase;

  WithdrawUseCase(
    this._authService,
    this._userRepository,
    this._userLocalDataSource,
    this._recordRepository,
    this._connectRepository,
    this._cancelAllNotificationsUseCase,
  );

  Future<void> execute({String? password}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // 1. Prove it's you (Google / Apple / email). Nothing is deleted yet.
    final reauth = await _authService.reauthenticateForDeletion(
      password: password,
    );

    // 2. The account (Apple token revoked first). The server cleans up.
    try {
      await _authService.deleteAccount(
        appleAuthorizationCode: reauth.appleAuthorizationCode,
      );
    } on FirebaseAuthException catch (e) {
      // A guest can't sign in again to prove it's them. Delete what the app
      // can reach, then sign out.
      if (e.code != 'requires-recent-login' || !user.isAnonymous) rethrow;
      await _deleteOwnDataBestEffort(user.uid);
      await _authService.signOut();
    }

    // 3. This device.
    try {
      await _cancelAllNotificationsUseCase.execute();
    } catch (e) {
      debugPrint('[WithdrawUseCase] notification cleanup skipped: $e');
    }
    await _userLocalDataSource.clearUser();
    AnalyticsService.log(AnalyticsEvent.accountDeleted);
  }

  Future<void> _deleteOwnDataBestEffort(String uid) async {
    Future<void> step(String name, Future<void> Function() run) async {
      try {
        await run();
      } catch (e) {
        debugPrint('[WithdrawUseCase] $name skipped: $e');
      }
    }

    await step('plans', () => _recordRepository.deletePlansByUserId(uid));
    await step(
      'relations',
      () => _connectRepository.deleteAllRelationsByUserId(uid),
    );
    await step('user', () => _userRepository.deleteUser(uid));
  }
}
