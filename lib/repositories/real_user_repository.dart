import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class RealUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    final inviteCode = _generateInviteCode();
    final newUser = UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName ?? '나', // Default name
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

      // 2. 이메일 동기화
      if (data['email'] != user.email && user.email != null) {
        updates['email'] = user.email;
      }

      // 3. 프로필 이미지 동기화
      if ((data['profileImageUrl'] == null ||
              data['profileImageUrl'].isEmpty) &&
          user.photoURL != null) {
        updates['profileImageUrl'] = user.photoURL;
      }

      // 4. InviteCode 백필
      if (data['inviteCode'] == null) {
        updates['inviteCode'] = _generateInviteCode();
      }

      // 업데이트할 항목이 있으면 실행
      if (updates.isNotEmpty) {
        debugPrint('User 데이터 동기화 수행: $updates');
        await userRef.update(updates);
      }
    }
  }

  String _generateInviteCode() {
    // 8자리 영문 대문자 + 숫자 (스펙 준수)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  @override
  Future<UserModel?> getMyProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      // TODO: 에러 핸들링
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

    try {
      // split into chunks of 10 if necessary (whereIn limit is 10 or 30?)
      // Firestore fieldIn limit is 30.
      final List<UserModel> users = [];

      // 10개씩 끊어서 조회 (안전하게)
      for (var i = 0; i < uids.length; i += 10) {
        final end = (i + 10 < uids.length) ? i + 10 : uids.length;
        final chunk = uids.sublist(i, end);

        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        users.addAll(snapshot.docs.map((doc) => UserModel.fromFirestore(doc)));
      }
      return users;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<UserModel?> getUserByInviteCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      // Error
    }
    return null;
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
      updates['displayName'] = name.isEmpty ? '나' : name;
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

      // 업로드
      final task = ref.putFile(image, metadata);

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
    } catch (e) {
      debugPrint('[RealUserRepository] updateFcmToken Error: $e');
      // FCM failed shouldn't crash app, just log
    }
  }
}
