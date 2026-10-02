<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (42 files)`
> - 문서 갱신: `2026-10-03 07:19:00 +0900`
<!-- COMMIT_STATUS END -->

# 설정(Settings)·앱 공통 정책

마지막 갱신: 2026-10-03 (1.1.0+81)

## 언어
- 한국어(ko)·영어(en). `appSettingsProvider`에 저장, 바꾸면 앱 전체 전환.
- BuildContext 없는 코드(저장소·알림)는 `contextFreeL10n()`으로 같은 ARB 문자열을 쓴다(설정 언어 → 기기 언어).
- 앱 이름: ko `둘운완`, en `DuoDone`. 탭: 지금 / 기록 / 우리.

## 테마 — 숨김
- 테마 선택 UI는 숨겼다(`_kShowThemePicker = false`).
- 앱은 항상 브랜드 팔레트로 시작한다(`AppSettingsNotifier.build()`가 저장된 `app.theme`를 무시, 저장소 키는 `smokyPlum`). 다른 4개 팔레트 코드는 남아 있다.
- 팔레트: primary `#D92653`, pressed `#B81C45`, soft `#FFE8ED`, secondary(인정 옐로) `#FFD84D`, background `#FFF8F6`, surface `#FFFFFF`, textPrimary `#2B1B21`, textSecondary `#6F5C63`. 노란색은 채움 전용, 텍스트는 `accentWine #8A5A00`. 상세 `docs/design/BRAND.md`.

## 앱 사용법
- 설정의 `앱 사용법` 행은 3장 튜토리얼(운동 약속을 걸어요 → 짝꿍이 보고 인정해요 → 둘 다 하면, 둘운완)을 다시 연다.
- 튜토리얼 완료 키는 아직 `nodtry_tutorial_completed_v1`이다. 옛 튜토리얼을 본 로그아웃 사용자는 새 이야기를 보지 않는다(키 변경 여부는 제품 결정 대기).

## 최소 버전 게이트 (신규)
- Firestore `config/app {minBuild: int, latestBuild: int}`. 로그인 전에도 공개 읽기, 클라이언트 쓰기 금지(콘솔·admin만).
- 앱 실행 시 1회, 3초 타임아웃으로 읽는다. 실패하거나 문서가 없으면 게이트 없음(fail-open).
- 설치 빌드 < `minBuild` → 전체 화면 `업데이트가 필요해요` + 스토어 버튼(차단).
- 설치 빌드 < `latestBuild` → 소프트 안내, `latestBuild`당 1회(`app.soft_update_dismissed_build`).
- 스토어 링크: Play `id=com.devho.nodtry.app`, App Store `https://apps.apple.com/kr/app/id6761373605`.
- 운영 값: 규칙 배포 직후 `{minBuild: 0, latestBuild: 80}`으로 만들고, 양 스토어 공개 1시간 뒤 `latestBuild: 81`. `minBuild`는 피벗 빌드가 충분히 퍼진 뒤에만 올린다(보안 묶음과 함께). `LAUNCH_RUNBOOK.md` 2·8단계.
- 앱이 다시 포그라운드로 와도 재확인하지 않는다.

## 기존 사용자 1회 공지 (신규)
- `그래,해봐가 둘운완이 됐어요` / `약속, 기록, 짝꿍 연결은 그대로예요.`
- 기존 사용자에게만: 이 기기에서 구버전이 돌았던 기록(옛 튜토리얼 플래그·캐시 프로필, `main()`에서 기록), 또는 계정 생성일 < 2026-10-02. 새 사용자에겐 안 뜬다.
- 기기에 저장(`pivot.notice_seen_v1`)하고 `users.pivotNoticeSeen`을 백업으로 쓴다.
- 이 ARB 키(`pivotNoticeTitle`)만 금지어 `그래,해봐` 예외다.

## 계정 관리
- 회원 탈퇴: 확인 다이얼로그 → 앱 cascade 삭제 → Auth 계정 삭제 → 서버 `onAuthUserDeleted`가 남은 데이터 정리. [auth_policy.md](./auth_policy.md)

## 개발자 옵션
- `kDebugMode`에서만. Firebase 리셋, 데이터 초기화, 가짜 카드 상태.

## 인앱 결제 (후원, 변경 없음)
- `donation_coffee` 소모품. `iapServiceProvider`. 분석 `donation_initiated`, `purchase`, `purchase_failed`.
- 결제·구독·보증금 기능은 없다.
