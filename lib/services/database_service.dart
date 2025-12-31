import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 사용자 문서 생성 (없으면 생성, 있으면 무시)
  ///
  /// Deprecated: Use `UserRepository.initializeUser` instead.
  @Deprecated('Use UserRepository.initializeUser instead')
  Future<void> createUser(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '나', // 기본값
        'profileImageUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'inviteCode': _generateInviteCode(), // 초대 코드 생성
      });
    }
  }

  /// 8자리 랜덤 초대 코드 생성 (대문자 + 숫자)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
