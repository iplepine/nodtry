# Crash & Error Reporting

Firebase Crashlytics를 통해 크래시와 비치명적(non-fatal) 에러를 수집한다.

## 현재 상태 (구현됨)

- `firebase_crashlytics` 의존성 추가 (`pubspec.yaml`).
- 전역 핸들러 설치: [`lib/utils/error_reporter.dart`](../../lib/utils/error_reporter.dart),
  `main()`에서 `ErrorReporter.initialize()` 호출.
  - `FlutterError.onError` → Flutter 프레임워크 에러 수집.
  - `PlatformDispatcher.instance.onError` → 잡히지 않은 비동기 에러 수집(fatal).
  - 디버그 빌드에서는 업로드 비활성(`setCrashlyticsCollectionEnabled(!kDebugMode)`).
- `ErrorReporter.record(e, s, reason: ...)`로 그동안 `debugPrint`로만 삼키던
  repository 실패(프로필/연결/FCM 토큰 조회 등)를 비치명적 이벤트로 보고.

**이 구성만으로 Dart 레이어 에러(대부분의 에러)는 완전한 스택트레이스로 수집된다.**
Dart 코드는 R8 난독화 대상이 아니며(별도 AOT 컴파일), `--obfuscate` 빌드를 쓰지 않는 한
역난독화 매핑이 불필요하다.

## 후속 과제 (선택) — 네이티브 심볼 업로드

release 빌드는 `isMinifyEnabled = true`(R8)이다. **네이티브(Java/Kotlin/NDK) 계층**의
크래시 스택트레이스까지 역난독화하려면 Crashlytics Gradle 플러그인이 필요하다. Dart 에러
수집에는 영향이 없으므로 빌드 안정성을 위해 별도 검증 후 적용한다.

1. `android/settings.gradle.kts` `plugins {}`:
   ```kotlin
   id("com.google.firebase.crashlytics") version "3.0.3" apply false
   ```
   (이 버전은 `com.google.gms.google-services` 4.4.x와 짝을 이룬다. 현재 4.3.15이므로
   같이 4.4.2로 올리거나, google-services 4.3.x를 유지하려면 Crashlytics 2.9.9를 쓴다.)
2. `android/app/build.gradle.kts` `plugins {}`:
   ```kotlin
   id("com.google.firebase.crashlytics")
   ```
3. 적용 후 반드시 `flutter build appbundle --release`로 빌드가 통과하는지 검증한다.

iOS는 FlutterFire가 dSYM 업로드를 자동 처리하므로 추가 설정이 없다(`firebase.json`의
`uploadDebugSymbols`는 빌드 단계에서 관리).
