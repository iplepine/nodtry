<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `f7edf13a1e4f2290e55313f2308eba2c886a9692` (`release/1.2.0`)
> - 최근 커밋: `f7edf13a1e4f` feat(growth): monthly recap, New Year 21-day challenge and KakaoTalk invite card
> - 커밋 일시: `2026-11-22T10:21:14+09:00`
> - 워킹트리: `dirty (16 files)`
> - 문서 갱신: `2026-11-22 10:21:15 +0900`
<!-- COMMIT_STATUS END -->

# 카카오톡 초대 카드 설정 (Kakao Share)

마지막 갱신: 2026-11-21 · 상태: **코드만 구현, 카카오 앱 미등록 · 실기기 미검증 · 미배포**

초대를 카카오톡 카드(이미지 + 문구 + "초대 확인하기" 버튼)로 보내는 기능입니다. `.env`에 `KAKAO_NATIVE_APP_KEY`가 없으면 앱은 지금과 똑같이 동작합니다(공유 시트만). 키를 넣고 새로 빌드해야 켜집니다.

- 코드: `lib/features/connect/application/kakao_invite_sharer.dart`, `invite_services.dart`(`shareMyInviteViaKakao`)
- SDK: `kakao_flutter_sdk_share` 2.1.0 (Flutter 3.38+ / Dart 3.9+ / iOS 13+ / Android minSdk 24)
- 카드 링크: `https://nod-try.web.app/i/{CODE}` 하나만 씁니다. 앱 실행 파라미터와 `kakao{키}://` URL 스킴은 쓰지 않습니다.

## 1. 대표가 할 일 (Kakao Developers 콘솔)

메뉴 이름은 2026-11 문서 기준입니다. 콘솔: <https://developers.kakao.com/console/app>

1. **앱 만들기** — 앱 이름 `둘운완`, 회사명, 앱 아이콘(카카오톡 카드 하단에 앱 이름·아이콘이 보입니다).
2. **[앱] > [플랫폼 키] > [네이티브 앱 키]** 에서 플랫폼 정보 등록
   - Android 패키지명: `com.devho.nodtry.app` (스토어 URL은 자동 입력)
   - Android 키 해시 **3개 모두**: 디버그, 업로드 키, Play 앱 서명 키 (아래 2번)
   - iOS 번들 ID: `com.devho.nodtry.app` (스토어 URL: `https://apps.apple.com/kr/app/id6761373605`)
3. **[앱] > [제품 링크 관리] > [웹 도메인]** 에 `https://nod-try.web.app` 등록 (경로 없이 도메인만). 등록되지 않은 도메인의 링크는 메시지에 쓸 수 없습니다.
   - 예전 "플랫폼 > Web > 사이트 도메인"이 이 메뉴로 바뀌었습니다. [JavaScript 키] > [JavaScript SDK 도메인]은 다른 설정이고 이 기능에는 필요 없습니다.
4. **네이티브 앱 키**를 복사해 프로젝트 루트 `.env`에 한 줄 추가
   ```
   KAKAO_NATIVE_APP_KEY=<네이티브 앱 키>
   ```
   `.env`는 앱 번들에 들어가므로 새 빌드부터 적용됩니다. 네이티브 앱 키는 앱에 담기는 공개용 키입니다(어드민 키·REST 키는 넣지 않습니다).

비즈 앱 전환·검수는 기본 공유에는 필요 없습니다(친구 선택 화면 커스터마이징에만 필요). 무료 쿼터를 넘는 트래픽만 유료입니다.

## 2. Android 키 해시 구하기

키 해시 = 서명 인증서 SHA-1을 Base64로 바꾼 값. 등록되지 않은 서명으로 빌드한 앱에서는 카드 전송이 실패하고 공유 시트로 넘어갑니다.

```bash
# 디버그 (개발 Mac마다 다름)
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore \
  -storepass android -keypass android | openssl sha1 -binary | openssl base64

# 업로드 키 (android/key.properties 의 keyAlias / storeFile)
keytool -exportcert -alias <keyAlias> -keystore <storeFile> | openssl sha1 -binary | openssl base64

# Play 앱 서명 키 — 스토어에서 받은 앱은 이 키로 서명됩니다 (가장 중요)
# Play Console > [설정] > [앱 무결성] > [앱 서명 키 인증서] 의 SHA-1 인증서 지문을 복사해서
echo "<SHA-1 지문, 콜론 포함 그대로>" | xxd -r -p | openssl base64
```

## 3. 네이티브 설정 (코드에 반영됨)

- iOS `Info.plist`: `LSApplicationQueriesSchemes`에 `kakaolink` 추가됨(카카오톡 설치 확인용).
- Android: 매니페스트 변경 없음. 카카오톡 패키지 조회(`<queries>`)는 SDK 플러그인이 병합합니다.
- 추가하지 않은 것: `kakao{키}://kakaolink` 인텐트 필터(Android) / URL Scheme(iOS). 카드 버튼이 앱 실행 링크가 아니라 웹 링크라서 필요 없습니다.
- 남은 작업: `cd ios && pod install` (새 플러그인 `kakao_flutter_sdk_common`), 그다음 Android·iOS 빌드 확인. 아직 실행하지 않았습니다.

## 4. 실기기 검증 (키 등록 후)

카카오톡이 설치된 실제 기기에서, Android(디버그 빌드 + Play 내부 테스트 빌드)와 iOS 각각:

1. 초대 화면·지금 탭 초대 카드에 노란 **카카오톡으로 초대 보내기** 버튼과 **다른 앱으로 보내기**가 보인다.
2. 버튼을 누르면 카카오톡 친구 선택 화면이 열리고, 보낸 카드에 이미지·제목·`코드 ABCD 2345`·**초대 확인하기** 버튼이 보인다.
3. 약속이 있을 때/없을 때 제목이 다르다("걸었어" / "걸 거야").
4. 앱으로 돌아오면 "초대를 보냈어요" 안내와 알림 권한 요청이 뜬다.
5. 받은 사람: **앱 미설치** 기기에서 버튼 → 초대 페이지 → 코드 복사 후 스토어. **앱 설치** 기기에서 버튼 → 앱이 초대 코드와 함께 열리는지.
6. 카카오톡이 없는 기기: 버튼이 지금과 같다(공유 시트 하나).
7. PC 카카오톡에서 카드 버튼이 초대 페이지를 연다.
8. Firebase DebugView에서 `invite_shared {channel: kakao_card}` 확인(디버그 빌드는 수집이 꺼져 있음 — `docs/operations/ANALYTICS_EVENTS.md`).

실패 시: 카드 대신 공유 시트가 뜨면 Crashlytics 비치명 오류 `kakao_invite_share`의 메시지를 봅니다(키 해시 불일치, 번들 ID 불일치, 웹 도메인 미등록이 대표 원인).

## 5. 미확인 · 위험

- **실제 카카오톡 전송 전체가 미검증**입니다. 자동 테스트는 가짜 공유기로 문구·대체 경로·화면만 확인했습니다.
- **설치된 앱으로 바로 열리는지 미확인.** 카드 버튼의 웹 링크는 카카오톡 인앱 브라우저에서 열릴 가능성이 높고, 인앱 브라우저에서는 Universal Link / App Link가 앱을 자동으로 열지 않을 수 있습니다. 그 경우 초대 페이지의 "이미 앱이 있다면 앱에서 열기" 버튼(`onmybehalf://`)이 대신합니다. 4-5에서 이 흐름이 불편하면 앱 실행 파라미터 + `kakao{키}://kakaolink` 스킴 추가를 다시 결정해야 합니다(카카오 문서의 링크 우선순위: 앱 실행 링크 → 스토어 → 모바일 웹).
- **전송 완료 여부를 알 수 없습니다.** SDK는 카카오톡을 여는 데까지만 알려 주므로, 친구 선택 화면에서 취소해도 "보냄"으로 기록됩니다(`invite_shared` 과대 집계, "초대 다시 보내기" 상태 전환, 서버 리마인더). 정확히 세려면 카카오톡 공유 웹훅(서버 필요)을 써야 합니다.
- 카드 문구(ko/en)는 기존 초대 메시지를 따라 쓴 초안입니다. 대표 확인 전입니다.
- Android/iOS 릴리스 빌드는 2026-11-22 성공 확인(AAB 79.6MB, Runner.app 59.3MB, 키 없는 상태). 이전 버전 대비 용량 변화와, 난독화된 릴리스 빌드에서 실제 카카오 전송이 되는지는 미확인.
