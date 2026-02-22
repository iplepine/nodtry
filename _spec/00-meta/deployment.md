# 배포 및 출시 가이드 (Deployment & Release)

## 1. 개요
이 문서는 `IfTogether` (구 OnMyBehalf) 앱의 자동화된 배포 및 출시 프로세스를 정의한다.

## 2. 버전 관리 (Versioning)
- **Semantic Versioning (Major.Minor.Patch)** 원칙을 따른다.
- **Build Number**는 자동 증가한다.
- `pubspec.yaml`이 버전의 기준이다.

## 3. 배포 자동화 (Android First)
현재 Android 빌드 및 배포가 자동화되어 있다. Fastlane을 사용하여 Google Play Console의 Internal Test Track으로 업로드한다.

### Android Fastlane
- **Track:** `internal`
- **Artifact:** `.aab`
- **Config:** `android/fastlane/`

## 4. 인증 (Secrets)
- **Service Account Key:** `android/fastlane/json_key.json`
- **Signing Key:** `android/key.properties`
1
## 5. 실행 방법 (Workflow)

VS Code Task **"Build & Deploy AAB"**를 실행하거나 다음 명령어를 사용한다.

```bash
./scripts/build_aab_deploy.sh [options]
```

### 프로세스
1. **버전 범프:** `pubspec.yaml` 업데이트
2. **Android 빌드:** `flutter build appbundle`
3. **Android 배포:** `fastlane internal`
4. **Git:** 커밋 및 태그 생성
