<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `d591e92e08aca84dcec3c09187fb4ab615b1419d` (`main`)
> - 최근 커밋: `d591e92e08ac` chore: bump version to 1.0.53+75 (now-tab timing & carousel swipe)
> - 커밋 일시: `2026-06-16T10:09:48+09:00`
> - 워킹트리: `dirty (64 files)`
> - 문서 갱신: `2026-06-20 22:33:15 +0900`
<!-- COMMIT_STATUS END -->

# Task

ID: `BT-007-notification-production-hardening`

유형: `Build/Release`

상태: `Done`

연결 Roadmap: `R-001-study-sprint-prep`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-05-10

## 목표

파일럿 시작 전에 파트너 똑똑, 놓친 약속 자동 전달, 주요 원격 알림이 실제 기기에서 보이는 푸시로 안정적으로 전달되게 하고 Android production 배포까지 완료한다.

## 배경

똑똑 버튼을 눌러도 상대방에게 푸시가 오지 않거나, `지금` 탭에서 똑똑 카드가 계속 남는 문제가 있었다. 파일럿에서 파트너 책임 신호가 핵심이므로 알림/카드 상태가 흐려지면 W1 실천과 파트너 피드백 지표를 제대로 검증할 수 없다.

## 포함

- Cloud Functions FCM payload를 data-only가 아니라 OS 표시 가능한 notification/APNS alert payload로 보강
- `poke`와 `cheer` 타입을 분리해 똑똑 수신자가 올바른 알림 타입을 받도록 수정
- `notifyMissedActions` 스케줄 함수 배포
- Functions 런타임 Node.js 22 전환
- `firebase-functions`, `firebase-admin`, `@types/node` 업데이트
- Now 탭에서 똑똑 전송 후 해당 카드 즉시 제거
- 파트너가 오늘 완료/건너뜀/휴식/구제 처리했거나 이미 똑똑을 받은 경우 `partnerPoke` 재생성 방지
- `1.0.30+49` Android internal, Android production, iOS TestFlight 배포

## 제외

- Play/App Store 정식 리뷰 자동화
- 푸시 수신률 대시보드
- 다대다 책임망

## 완료 기준

- [x] Cloud Functions 배포 완료
- [x] Android production track 배포 완료
- [x] iOS TestFlight 업로드 완료
- [x] 똑똑 전송 후 Now 탭 카드가 즉시 정리됨
- [x] 같은 날 같은 플랜의 `partnerPoke` 카드가 반복 생성되지 않음
- [x] 관련 테스트와 릴리즈 문서 갱신

## 검증 결과

명령:

- `npm --prefix functions run build`
- `firebase deploy --only functions`
- `flutter test test/viewmodels/now_tab_viewmodel_test.dart test/models/partner_plan_state_test.dart`
- `fastlane deploy_all`
- `fastlane run upload_to_play_store track:internal track_promote_to:production track_promote_release_status:completed release_status:completed version_code:49 metadata_path:fastlane/metadata/android skip_upload_apk:true skip_upload_aab:true skip_upload_images:true skip_upload_screenshots:true`

결과:

- Cloud Functions Node.js 22 배포 완료.
- Android `1.0.30+49` internal track 업로드 완료.
- Android `1.0.30+49` production track 승격 완료.
- iOS `1.0.30+49` TestFlight 업로드 완료. App Store Connect 처리 완료는 몇 분 지연될 수 있다.

## 남은 리스크

- 실제 푸시 수신은 상대방의 알림 권한, FCM 토큰 저장, 기기 상태에 의존한다.
- `notifyMissedActions`는 30분 주기라 놓친 약속 푸시가 즉시 오지는 않는다.
- `npm audit --omit=dev`는 `firebase-admin@13.9.0`에서 low severity 9개를 보고하지만, 자동 force fix가 구버전 다운그레이드를 제안해 적용하지 않았다.

## 후속 task

- `BT-004-pilot-recruitment-ops`
- `BT-005-week-one-pilot-ops-review`
