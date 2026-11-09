import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_provider.dart';

/// Tells the server an invite went out, so it can send the inviter a gentle
/// reminder when their partner hasn't joined yet (the hourly
/// `sendInviteReminders` function).
///
/// `invites/{uid}`: `{inviterUid, code, createdAt, lastSharedAt, shareCount}`
/// — the only fields the app may write (firestore.rules). The reminder
/// bookkeeping on the same doc (`remindersSent`, `connectedAt`, …) is the
/// server's; a new share starts a new reminder cycle by itself.
abstract class InviteTracker {
  Future<void> recordShare({required String uid, required String code});
}

class FirestoreInviteTracker implements InviteTracker {
  FirestoreInviteTracker(this._db);

  final FirebaseFirestore Function() _db;

  static const collection = 'invites';

  @override
  Future<void> recordShare({required String uid, required String code}) async {
    final ref = _db().collection(collection).doc(uid);
    Future<void> reshare() => ref.update({
      'code': code,
      'lastSharedAt': FieldValue.serverTimestamp(),
      'shareCount': FieldValue.increment(1),
    });

    final snapshot = await ref.get();
    if (snapshot.exists) {
      await reshare();
      return;
    }
    try {
      await ref.set({
        'inviterUid': uid,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSharedAt': FieldValue.serverTimestamp(),
        'shareCount': 1,
      });
    } on FirebaseException {
      // The doc exists after all (a stale cache said otherwise): the rules
      // only accept the re-share update then.
      await reshare();
    }
  }
}

/// Does nothing: mock repositories (developer mode) never touch Firestore.
class NoopInviteTracker implements InviteTracker {
  const NoopInviteTracker();

  @override
  Future<void> recordShare({required String uid, required String code}) async {}
}

final inviteTrackerProvider = Provider<InviteTracker>((ref) {
  final type =
      ref.watch(repositoryTypeProvider).asData?.value ?? RepositoryType.real;
  if (type == RepositoryType.mock) return const NoopInviteTracker();
  return FirestoreInviteTracker(() => FirebaseFirestore.instance);
});

/// Records an invite share without ever failing or holding up the caller:
/// a reminder that can't be scheduled is not worth an error.
Future<void> recordInviteShare(
  InviteTracker tracker, {
  required String uid,
  required String code,
}) async {
  try {
    await tracker.recordShare(uid: uid, code: code);
  } catch (_) {
    // Offline, signed out meanwhile, or no Firebase (tests): skip.
  }
}
