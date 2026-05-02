# iOS Release Runbook

## 목적
- iOS App Store 배포 절차를 한 번에 재현 가능하게 정리한다.
- Apple 로그인, Firebase, fastlane, App Store Connect에서 자주 터지는 문제를 빠르게 좁힌다.

## 현재 기준 경로
- 워크스페이스: `ios/Runner.xcworkspace`
- fastlane: `ios/fastlane/Fastfile`
- 버전 소스: `pubspec.yaml`
- iOS 앱 번들 ID: `com.devho.nodtry.app`
- Apple Services ID: `com.devho.nodtry.app.signin`

## 배포 전 체크
1. `pubspec.yaml`의 `version`을 새 값으로 올린다.
2. Apple 로그인 관련 값이 아래와 일치하는지 본다.
   - App ID / Bundle ID: `com.devho.nodtry.app`
   - Xcode Capability: `Sign in with Apple`
   - Firebase Apple provider 활성화
   - Firebase `Service ID`, `Team ID`, `Key ID`, `Private Key`
3. `ios/Runner/GoogleService-Info.plist`가 현재 Firebase 프로젝트와 일치하는지 확인한다.
4. iOS는 반드시 `Runner.xcworkspace` 기준으로 연다.
5. App Store Connect에 같은 `versionString`이 이미 사용되었는지 확인한다.

## 릴리즈 명령
프로젝트 루트:

```bash
cd ios
fastlane release
```

현재 lane 동작:
1. 배포 직전에 `scripts/generate_ios_release_notes.sh`가 `ios/fastlane/metadata/ko/release_notes.txt`를 자동 생성한다.
2. `build_app`로 새 아카이브와 `build/ios/ipa/nodtry.ipa`를 생성한다.
3. `upload_to_app_store`로 App Store Connect에 업로드한다.

## 버전 관리 규칙
- `pubspec.yaml`의 `version`이 기준이다.
- 형식: `marketing_version+build_number`
- 예: `1.0.21+40`
- App Store Connect가 `The version number has been previously used`를 반환하면 `marketing_version`을 올린다.

## 권장 배포 순서
1. `pubspec.yaml` 버전 업데이트
2. 작업 트리 확인
3. `cd ios && fastlane release`
4. 업로드 성공 후 App Store Connect에서 빌드 처리 상태 확인
5. 자동 생성된 릴리즈 노트 확인, 심사 제출, 출시 시점 결정

## 자주 터지는 문제

### 1. `No such module 'Flutter'`
원인:
- `Runner.xcodeproj`로 열었거나 Pods/workspace가 깨짐

대응:
1. `flutter clean`
2. `flutter pub get`
3. `cd ios && pod install`
4. `ios/Runner.xcworkspace`로 다시 연다

### 2. `same file ... ipa`
원인:
- fastlane `output_name`에 한글 파일명을 써서 macOS 정규화 충돌 발생

대응:
- IPA 파일명은 ASCII만 사용한다
- 현재 표준값: `nodtry.ipa`

### 3. `The version number has been previously used`
원인:
- App Store Connect에 같은 마케팅 버전이 이미 존재함

대응:
- `pubspec.yaml`의 버전을 올린 뒤 다시 빌드/업로드

### 4. Apple 로그인 `invalid-credential`
원인 후보:
- Firebase Apple provider의 `Key ID`와 `.p8` 불일치
- `Service ID`, `Team ID`, `Bundle ID` 불일치
- 앱이 옛 빌드라서 잘못된 에러 문구를 보여줌

확인 순서:
1. Apple Developer App ID / Services ID / Keys 확인
2. Firebase Apple provider 값 대조
3. 실기기에서 최신 빌드로 재설치 후 테스트

### 5. `Could not extract value ... NSBonjourServices`
원인:
- Info.plist에 로컬 네트워크 관련 키가 빠졌거나 빌드 캐시가 꼬임

현재 반영된 키:
- `NSLocalNetworkUsageDescription`
- `NSBonjourServices`

### 6. `AuthorizationErrorCode ... switch must be exhaustive`
원인:
- 플러그인 enum이 추가되었는데 앱 코드 또는 플러그인에서 switch가 방어적으로 처리되지 않음

대응:
- 앱 코드에서는 `default` 또는 fallback 분기 포함
- 플러그인 경고는 빌드 차단이 아닌 경우가 많지만, 업데이트 시 다시 확인

## Apple 로그인 설정 점검표
Apple Developer:
- App ID: `com.devho.nodtry.app`
- `Sign in with Apple` 활성화
- Services ID: `com.devho.nodtry.app.signin`
- Team ID 확인
- Sign in with Apple용 Key 생성 및 `Key ID` 확인

Firebase:
- Authentication > Apple provider 활성화
- `Service ID`
- `Apple Team ID`
- `Key ID`
- `Private Key (.p8 전체 내용)`

앱:
- `Runner.xcworkspace`
- `Sign in with Apple` capability
- 최신 빌드 재설치 후 실기기 확인

## 배포 후 확인
1. App Store Connect에서 업로드된 빌드 버전 확인
2. Processing 완료 확인
3. 필요한 경우 TestFlight 내부 테스트 먼저 검증
4. App Store 릴리즈 생성 및 제출

## 이 문서를 먼저 볼 상황
- 오랜만에 iOS 배포할 때
- Apple 로그인 관련 설정을 건드린 뒤
- fastlane이 archive/export/upload 중 어디서 실패했는지 빠르게 좁혀야 할 때
