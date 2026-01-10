import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 현재 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  /// 익명 로그인 (게스트)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
      rethrow;
    }
  }

  /// 구글 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled the sign-in

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      rethrow;
    }
  }

  /// 이메일 회원가입
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Error signing up with email: $e");
      rethrow;
    }
  }

  /// 이메일 로그인
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Error signing in with email: $e");
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
      rethrow;
    }
  }

  /// 익명 계정을 영구 계정(구글)으로 전환 (계정 연결)
  Future<UserCredential?> linkWithGoogle() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No current user');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled the sign-in

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link credential to current user
      return await currentUser.linkWithCredential(credential);
    } catch (e) {
      debugPrint("Error linking with Google: $e");
      rethrow;
    }
  }

  /// 익명 계정을 이메일 계정으로 전환 (계정 연결)
  Future<UserCredential?> linkWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No current user');

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      return await currentUser.linkWithCredential(credential);
    } catch (e) {
      debugPrint("Error linking with Email: $e");
      rethrow;
    }
  }

  /// 회원 탈퇴 (계정 삭제)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 구글 로그인 사용자의 경우 재인증 필요할 수 있음
        // (민감한 작업 전 재인증 로직은 UseCase 레벨에서 처리 권장하지만, 편의상 여기서 호출 가능)
        // 여기서는 단순 삭제 시도
        if (_googleSignIn.currentUser != null) {
          await _googleSignIn.disconnect();
        }
        await user.delete();
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
      rethrow;
    }
  }
}
