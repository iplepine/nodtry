---
name: ios-release
description: Use when preparing or running an iOS App Store release for this Flutter project, including version bumps, fastlane release runs, Apple sign-in deployment checks, and App Store Connect upload failures.
---

# iOS Release

이 스킬은 이 저장소의 iOS App Store 배포 절차를 빠르게 재현하기 위한 것이다.

## 먼저 읽을 문서
- 배포 절차와 트러블슈팅은 [`_spec/00-meta/workflow/ios-release-runbook.md`](../../../_spec/00-meta/workflow/ios-release-runbook.md)에 정리돼 있다.

## 기본 원칙
- iOS는 항상 `ios/Runner.xcworkspace` 기준으로 본다.
- 버전 기준은 `pubspec.yaml`이다.
- App Store 업로드는 `cd ios && fastlane release`를 기본 경로로 사용한다.
- IPA 파일명은 ASCII만 사용한다.

## 실행 순서
1. `pubspec.yaml`의 `version` 확인 또는 증가
2. Apple/Firebase 로그인 설정이 최근 변경되었다면 런북의 Apple 로그인 점검표 확인
3. `ios/fastlane/Fastfile`의 `release` lane이 새 IPA를 빌드하도록 되어 있는지 확인
4. `cd ios && fastlane release` 실행
5. 실패 지점을 아래 분류로 좁힌다

## 실패 분류

### Build/Workspace
- `No such module 'Flutter'`
- `Runner.xcodeproj`로 열림
- Pods/workspace 손상

대응:
- 런북의 `No such module 'Flutter'` 절차를 따른다.

### Export
- IPA 파일명 충돌
- exportArchive 단계 실패

대응:
- 한글 파일명 대신 ASCII `nodtry.ipa` 사용 여부 확인

### Upload
- `The version number has been previously used`

대응:
- `pubspec.yaml`의 마케팅 버전을 올리고 다시 배포

### Auth
- Apple 로그인 `invalid-credential`

대응:
- 런북의 Apple 로그인 점검표 순서대로 App ID, Services ID, Team ID, Key ID, `.p8`를 대조

## 이 스킬이 다루는 로컬 파일
- `pubspec.yaml`
- `ios/fastlane/Fastfile`
- `ios/Runner/Info.plist`
- `lib/services/auth_service.dart`

## 출력 기대값
- 현재 막힌 단계가 `build`, `export`, `upload`, `auth` 중 어디인지 명확히 말한다.
- 수정이 필요하면 가능한 한 바로 패치한다.
- 업로드 실패면 App Store Connect나 fastlane 에러 문구를 짧게 요약하고 다음 조치를 제시한다.
