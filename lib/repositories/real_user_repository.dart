import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class RealUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<void> initializeUser(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      final snapshot = await userRef.get();
      if (!snapshot.exists) {
        // 신규 유저 생성
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': (user.displayName == null || user.displayName!.isEmpty)
              ? '나'
              : user.displayName,
          'photoURL': user.photoURL,
          'isAnonymous': user.isAnonymous,
          'inviteCode': _generateInviteCode(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 기존 유저: 마지막 접속일 등 업데이트 필요 시 여기에 추가
      }
    } catch (e) {
      // TODO: 에러 처리
      // print('initializeUser Error: $e');
    }
  }

  String _generateInviteCode() {
    // 8자리 영문 대문자 + 숫자 (스펙 준수)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(DateTime.now().microsecond % chars.length),
      ),
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
    File? image,
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

    // 이미지 업로드는 Storage 설정 후 구현 필요
    // if (image != null) {
    //   final url = await _uploadImage(user.uid, image);
    //   updates['profileImageUrl'] = url;
    // }

    await _firestore.collection('users').doc(user.uid).update(updates);
  }
}
