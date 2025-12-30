import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class RealUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    if (name != null) updates['displayName'] = name;
    if (statusMessage != null) updates['statusMessage'] = statusMessage;

    // 이미지 업로드는 Storage 설정 후 구현 필요
    // if (image != null) {
    //   final url = await _uploadImage(user.uid, image);
    //   updates['profileImageUrl'] = url;
    // }

    await _firestore.collection('users').doc(user.uid).update(updates);
  }
}
