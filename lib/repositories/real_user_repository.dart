import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../features/connect/domain/invite_code.dart';
import '../features/connect/domain/partner_label.dart';
import '../features/proof/domain/proof_photo_processing.dart';
import '../models/user_model.dart';
import '../utils/error_reporter.dart';
import 'connect_repository.dart';
import 'invite_code_callables.dart';
import 'user_repository.dart';

/// Users are read one document at a time, by uid (firestore.rules.next denies
/// listing the collection); invite codes are looked up by the
/// `resolveInviteCode` callable. The client never writes `users.email` (the
/// account's own email comes from FirebaseAuth).
class RealUserRepository implements UserRepository {
  RealUserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    CallableInvoker? callables,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageOverride = storage,
       _callables = callables ?? firebaseCallableInvoker;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage? _storageOverride;
  final CallableInvoker _callables;

  /// Resolved on first use so tests that never upload don't need Storage.
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  @override
  Future<void> initializeUser(User user) async {
    // 2. Determine Login Type
    LoginType loginType = LoginType.guest;
    if (!user.isAnonymous) {
      if (user.providerData.any(
        (userInfo) => userInfo.providerId == 'google.com',
      )) {
        loginType = LoginType.google;
      } else if (user.providerData.any(
        (userInfo) => userInfo.providerId == 'apple.com',
      )) {
        loginType = LoginType.apple;
      } else if (user.providerData.any(
        (userInfo) => userInfo.providerId == 'password',
      )) {
        loginType = LoginType.email;
      }
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    // Force fetch from server to check existence accurately
    // If offline, this might fail, but for account creation/init, we usually need online.
    // Or we use try-catch on 'get' to fallback?
    // Let's stick to default get() for offline support, but handle Update failure.
    DocumentSnapshot<Map<String, dynamic>> userDoc;
    try {
      userDoc = await userRef.get();
    } catch (e) {
      // If get fails (e.g. permission), try proceeding as if new?
      // No, rethrow.
      debugPrint('[RealUserRepository] Failed to get user doc: $e');
      rethrow;
    }

    try {
      if (!userDoc.exists) {
        await _createNewUser(userRef, user, loginType);
      } else {
        // Update Existing
        try {
          await _updateExistingUser(userRef, userDoc, user, loginType);
        } catch (e) {
          // If update fails because doc is missing (race condition or cache mismatch), try creating
          if (e is FirebaseException && e.code == 'not-found') {
            debugPrint(
              '[RealUserRepository] User found in cache but missing on server. Re-creating.',
            );
            await _createNewUser(userRef, user, loginType);
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('initializeUser Error: $e');
      rethrow; // Vital to rethrow so caller knows init failed
    }
  }

  Future<void> _createNewUser(
    DocumentReference userRef,
    User user,
    LoginType loginType,
  ) async {
    final inviteCode = _newInviteCode();
    final newUser = UserModel(
      uid: user.uid,
      // No email: users docs are readable by any signed-in user, and the
      // account's email is read from FirebaseAuth where it's needed.
      // No name stays no name: the placeholder '나' / 'Me' used to be
      // stored and then shown to the *partner* as this user's name. The app
      // shows "나" on my own screens when the name is missing.
      displayName: _nonEmpty(user.displayName),
      profileImageUrl: user.photoURL,
      loginType: loginType,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await userRef.set(newUser.toFirestore());
  }

  Future<void> _updateExistingUser(
    DocumentReference userRef,
    DocumentSnapshot<Map<String, dynamic>> userDoc,
    User user,
    LoginType loginType,
  ) async {
    final existingData = userDoc.data();
    final currentLoginTypeName = existingData?['loginType'];

    if (currentLoginTypeName != loginType.name) {
      await userRef.update({
        'loginType': loginType.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 기존 유저: 데이터 동기화 (Auth vs Firestore)
    final data = userDoc.data();
    if (data != null) {
      final updates = <String, dynamic>{};

      // 1. 익명 여부 동기화
      if (data['isAnonymous'] != user.isAnonymous) {
        updates['isAnonymous'] = user.isAnonymous;
      }

      // 2. 이메일은 더 이상 users 문서에 쓰지 않는다 (누구나 읽을 수 있는
      //    문서라서). 이미 저장된 값은 운영 마이그레이션
      //    (scripts/migrations/strip_user_emails.js)이 지운다.

      // 3. 프로필 이미지 동기화
      if ((data['profileImageUrl'] == null ||
              data['profileImageUrl'].isEmpty) &&
          user.photoURL != null) {
        updates['profileImageUrl'] = user.photoURL;
      }

      // 4. InviteCode 백필
      if (data['inviteCode'] == null) {
        updates['inviteCode'] = _newInviteCode();
      }

      // 업데이트할 항목이 있으면 실행
      if (updates.isNotEmpty) {
        debugPrint('User 데이터 동기화 수행: $updates');
        await userRef.update(updates);
      }
    }
  }

  /// A new code from the easy-to-read alphabet (no 0/O/1/I/L), drawn with
  /// Random.secure. No uniqueness lookup: firestore.rules.next denies
  /// querying users, 31^8 codes make a clash vanishingly rare, and the server
  /// re-issues a duplicated code the moment anyone looks it up (codeHolders)
  /// and rotates codes after every link anyway.
  String _newInviteCode() => generateInviteCode();

  @override
  Future<UserModel?> getMyProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'getMyProfile');
    }
    return null;
  }

  @override
  Stream<UserModel?> watchMyProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc);
        })
        .handleError((error) {
          debugPrint('watchMyProfile Error: $error');
          return null;
        });
  }

  @override
  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];

    // One get per uid, in parallel (a couple has one partner, so N is tiny).
    // A `documentId in [...]` query is a list, which rules.next denies on
    // users. A missing or unreadable profile is skipped, not fatal.
    final users = await Future.wait(
      uids.toSet().map((uid) async {
        try {
          final doc = await _firestore.collection('users').doc(uid).get();
          return doc.exists ? UserModel.fromFirestore(doc) : null;
        } catch (e, s) {
          ErrorReporter.record(e, s, reason: 'getUsersByIds');
          return null;
        }
      }),
    );
    return users.whereType<UserModel>().toList();
  }

  @override
  Future<UserModel?> getUserByInviteCode(String code) async {
    final normalized = normalizeInviteCode(code);
    if (!isValidInviteCode(normalized)) return null;
    final myUid = _auth.currentUser?.uid;

    final ResolvedInviter owner;
    try {
      owner = ResolvedInviter.fromData(
        await _callables(kResolveInviteCodeCallable, {'code': normalized}),
      );
    } catch (e) {
      switch (inviteCallableFailureOf(e)) {
        case InviteCallableFailure.unavailable:
          return _userByInviteCodeDirectly(normalized, myUid);
        case InviteCallableFailure.notFound:
        case InviteCallableFailure.codeFormat:
          return null;
        case InviteCallableFailure.selfCode:
          throw const InviteCodeIsMineException();
        case InviteCallableFailure.selfTaken:
        case InviteCallableFailure.ownerTaken:
        case InviteCallableFailure.rateLimited:
        case null:
          rethrow;
      }
    }
    if (owner.uid == myUid) throw const InviteCodeIsMineException();
    // Only what the confirm sheet shows; the rest of the profile is read by
    // uid once we're linked.
    final now = DateTime.now();
    return UserModel(
      uid: owner.uid,
      displayName: owner.displayName,
      profileImageUrl: owner.profileImageUrl,
      inviteCode: normalized,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// The pre-callable lookup (builds ≤80 did only this): a users query by
  /// inviteCode, which firestore.rules.next denies. Used only while the
  /// backend doesn't have `resolveInviteCode` yet.
  Future<UserModel?> _userByInviteCodeDirectly(
    String normalized,
    String? myUid,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('users')
          .where('inviteCode', isEqualTo: normalized)
          .limit(1)
          .get();
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'getUserByInviteCode');
      return null;
    }
    if (snapshot.docs.isEmpty) return null;
    final owner = UserModel.fromFirestore(snapshot.docs.first);
    if (owner.uid == myUid) throw const InviteCodeIsMineException();
    return owner;
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? statusMessage,
    String? imagePath,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      final trimmed = name.trim();
      updates['displayName'] = trimmed.isEmpty ? FieldValue.delete() : trimmed;
    }
    if (statusMessage != null) updates['statusMessage'] = statusMessage;

    if (imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        final url = await _uploadImage(user.uid, file);
        updates['profileImageUrl'] = url;
      }
    }

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      // 1. 유저 문서 삭제
      await _firestore.collection('users').doc(uid).delete();

      // 2. Storage의 프로필 이미지 삭제 (옵션, 로직 복잡하므로 MVP에서는 스킵 또는 필요시 구현)
      // Storage는 폴더 삭제가 안되므로 파일 목록 가져와서 삭제해야 함.
      // 여기서는 일단 DB 데이터만 삭제합니다.
      debugPrint('[RealUserRepository] User $uid deleted from Firestore');
    } catch (e) {
      debugPrint('[RealUserRepository] deleteUser Error: $e');
      rethrow;
    }
  }

  Future<String> _uploadImage(String uid, File image) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('users/$uid/profile_$timestamp.jpg');
      // 메타데이터 설정 (선택사항)
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uid': uid},
      );

      debugPrint('[RealUserRepository] uploading image to ${ref.fullPath}...');
      debugPrint(
        '[RealUserRepository] Source file: ${image.path}, exists: ${image.existsSync()}',
      );

      // Re-encoded before upload, like proof photos: the cropper (uCrop on
      // Android) copies EXIF — GPS included — into its output, and profile
      // images are readable by any signed-in user.
      final clean = await sanitizeImageBytesInBackground(
        await image.readAsBytes(),
      );
      if (clean == null) {
        throw Exception('Profile image could not be processed');
      }

      // 업로드
      final task = ref.putData(clean, metadata);

      // 진행률 모니터링 (옵션)
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint(
          '[RealUserRepository] Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
        );
      });

      await task;
      final snapshot = task.snapshot;
      debugPrint(
        '[RealUserRepository] Upload task finished. State: ${snapshot.state}',
      );

      if (snapshot.state == TaskState.success) {
        // 다운로드 URL 가져오기
        final url = await ref.getDownloadURL();
        debugPrint('[RealUserRepository] Download URL retrieved: $url');
        return url;
      } else {
        throw Exception('Image upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      debugPrint('[RealUserRepository] _uploadImage Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[RealUserRepository] FCM Token updated for $uid');
    } catch (e, s) {
      // FCM token persistence is best-effort, but a silent failure means the
      // user stops receiving partner signals — surface it to Crashlytics.
      ErrorReporter.record(e, s, reason: 'updateFcmToken');
    }
  }

  @override
  Future<void> updatePartnerNickname(String? nickname) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    final value = normalizePartnerNickname(nickname);
    await _firestore.collection('users').doc(user.uid).update({
      'partnerNickname': value ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markTermsAccepted() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'termsAcceptedAt': FieldValue.serverTimestamp(),
        'termsVersion': kTermsVersion,
      });
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'markTermsAccepted');
    }
  }

  @override
  Future<void> markPivotNoticeSeen() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'pivotNoticeSeen': true,
      });
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'markPivotNoticeSeen');
    }
  }

  @override
  Future<void> clearFcmToken(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[RealUserRepository] FCM Token cleared for $uid');
    } catch (e, s) {
      ErrorReporter.record(e, s, reason: 'clearFcmToken');
    }
  }
}

/// The version of the terms of use the app shows (bump with the terms page).
const int kTermsVersion = 1;

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
