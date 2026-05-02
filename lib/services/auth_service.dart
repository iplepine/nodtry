import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Exception _mapAppleFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return Exception(
          'Firebase Auth에서 Apple 로그인이 비활성화되어 있습니다. Firebase Console에서 Apple 제공업체를 켜 주세요.',
        );
      case 'invalid-credential':
      case 'invalid-oauth-response':
      case 'credential-already-in-use':
        return Exception(
          'Apple 로그인 자격 증명이 유효하지 않습니다. Apple 로그인 Capability, Bundle ID, Firebase Apple provider 설정을 확인해 주세요.',
        );
      case 'missing-or-invalid-nonce':
        return Exception('Apple 로그인 nonce 검증에 실패했습니다. 다시 시도해 주세요.');
      default:
        return Exception(e.message ?? 'Apple 로그인 중 오류가 발생했습니다. (${e.code})');
    }
  }

  Exception _mapAppleAuthorizationException(
    SignInWithAppleAuthorizationException e,
  ) {
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        return Exception('Apple 로그인이 취소되었습니다.');
      case AuthorizationErrorCode.credentialExport:
        return Exception('Apple 로그인 자격 증명을 내보내는 중 오류가 발생했습니다.');
      case AuthorizationErrorCode.credentialImport:
        return Exception('Apple 로그인 자격 증명을 가져오는 중 오류가 발생했습니다.');
      case AuthorizationErrorCode.failed:
        return Exception('Apple 로그인에 실패했습니다. 기기 Apple ID 상태를 확인해 주세요.');
      case AuthorizationErrorCode.invalidResponse:
        return Exception('Apple 로그인 응답이 올바르지 않습니다.');
      case AuthorizationErrorCode.notHandled:
        return Exception('Apple 로그인 요청을 처리하지 못했습니다.');
      case AuthorizationErrorCode.notInteractive:
        return Exception('Apple 로그인 UI를 표시할 수 없는 상태입니다.');
      case AuthorizationErrorCode.unknown:
        return Exception('Apple 로그인 중 알 수 없는 오류가 발생했습니다.');
      default:
        return Exception('Apple 로그인 중 오류가 발생했습니다. (${e.code.name})');
    }
  }

  /// Apple 로그인
  Future<UserCredential?> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception(
          '이 기기에서는 Apple 로그인을 사용할 수 없습니다. iOS 설정의 Apple ID 로그인 상태와 Sign in with Apple 지원 여부를 확인해 주세요.',
        );
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple identity token을 받지 못했습니다. 다시 시도해 주세요.');
      }

      final oauthCredential = AppleAuthProvider.credentialWithIDToken(
        identityToken,
        rawNonce,
        AppleFullPersonName(
          givenName: appleCredential.givenName,
          familyName: appleCredential.familyName,
        ),
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple은 최초 로그인 시에만 이름을 제공하므로 displayName 업데이트
      if (userCredential.user?.displayName == null ||
          userCredential.user!.displayName!.isEmpty) {
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;
        if (givenName != null || familyName != null) {
          final displayName = [
            givenName,
            familyName,
          ].where((s) => s != null && s.isNotEmpty).join(' ');
          if (displayName.isNotEmpty) {
            await userCredential.user?.updateDisplayName(displayName);
          }
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Error signing in with Apple: $e");
      throw _mapAppleFirebaseException(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      debugPrint("Error signing in with Apple: $e");
      throw _mapAppleAuthorizationException(e);
    } on PlatformException catch (e) {
      debugPrint("Error signing in with Apple: $e");
      throw Exception(
        e.message ?? 'Apple 로그인 플랫폼 처리 중 오류가 발생했습니다. (${e.code})',
      );
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

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception(
          '이 기기에서는 Apple 로그인을 사용할 수 없습니다. iOS 설정의 Apple ID 로그인 상태와 Sign in with Apple 지원 여부를 확인해 주세요.',
        );
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple identity token을 받지 못했습니다. 다시 시도해 주세요.');
      }

      final oauthCredential = AppleAuthProvider.credentialWithIDToken(
        identityToken,
        rawNonce,
        AppleFullPersonName(
          givenName: appleCredential.givenName,
          familyName: appleCredential.familyName,
        ),
      );

      return await currentUser.linkWithCredential(oauthCredential);
    } on FirebaseAuthException catch (e) {
      debugPrint("Error linking with Apple: $e");
      throw _mapAppleFirebaseException(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      debugPrint("Error linking with Apple: $e");
      throw _mapAppleAuthorizationException(e);
    } on PlatformException catch (e) {
      debugPrint("Error linking with Apple: $e");
      throw Exception(
        e.message ?? 'Apple 로그인 플랫폼 처리 중 오류가 발생했습니다. (${e.code})',
      );
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
