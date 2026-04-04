import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  /// Apple 로그인용 nonce 생성
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Apple 로그인
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple은 최초 로그인 시에만 이름을 제공하므로 displayName 업데이트
      if (userCredential.user?.displayName == null || userCredential.user!.displayName!.isEmpty) {
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;
        if (givenName != null || familyName != null) {
          final displayName = [givenName, familyName].where((s) => s != null && s.isNotEmpty).join(' ');
          if (displayName.isNotEmpty) {
            await userCredential.user?.updateDisplayName(displayName);
          }
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw Exception('Apple 로그인은 실제 기기에서만 가능합니다. 시뮬레이터에서는 지원되지 않습니다.');
      }
      debugPrint("Error signing in with Apple: $e");
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      debugPrint("Error signing in with Apple: $e");
      rethrow;
    } catch (e) {
      debugPrint("Error signing in with Apple: $e");
      rethrow;
    }
  }

  /// 익명 계정을 Apple 계정으로 전환 (계정 연결)
  Future<UserCredential?> linkWithApple() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No current user');

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      return await currentUser.linkWithCredential(oauthCredential);
    } catch (e) {
      debugPrint("Error linking with Apple: $e");
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
