<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 알림(Notification) 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S6·backend). 서버 변경은 **functions 배포 즉시 모든 사용자(구버전 포함)에게 적용**된다.

## 문구 규칙 (공통)
- 발신자 라벨: 수신자의 `users.partnerNickname` → 발신자 `displayName` → `짝꿍`(`copy.ts` `partnerLabel`). `{name}님` 금지, 푸시에 앱 이름 넣지 않음.
- `workoutType`이 있으면 운동 카피(타일 이모지·이름, 식단은 `식단`이고 `운동`·`오운완` 안 씀), 없으면 중립 `약속` 카피.
- 짝꿍 전달 문구는 반말, 시스템 안내는 해요체.
- 푸시는 현재 한국어만. ko/en 분기(`users.locale`)는 다음 릴리스.
- `data.type` 기존 값은 바꾸지 않는다. 새 타입은 구버전이 무시해도 안전해야 한다.

## 1. 로컬 알림 (마감 리마인더)
- 약속 생성·수정 시 다음 4주치 요일별 one-shot으로 예약(앱 재시작 후 복원).
- 제목: 운동 약속이면 히어로 질문 `오늘 🏃 러닝 했어?`(반말), 레거시면 약속 한 줄.
- 본문: 짝꿍 있음 `기록이 없으면 곧 {애칭}한테 알려져요`(분 단위 약속 금지) / 혼자 `인증 한 번이면 오늘 기록 끝이에요 📸`.
- 애칭은 예약 시점 값이다. 나중에 바꾼 애칭은 다음 재예약(재실행 복원·약속 수정) 때 반영.
- 업데이트 후 1회 전체 재예약: `reminderCopyRefreshBinderProvider`, prefs `notif.reminder_copy_version = 81`. 약속 읽기 실패·빈 결과면 다음 실행에 재시도.
- 앱 시작 복원 시 **오늘 이미 기록한 약속의 오늘 알림은 빼고** 예약한다(피벗에서 수정: 기록 후에도 "기록이 없으면…"이 뜨던 문제).
- 액션: `했어`(앱 열고 메모 입력), `오늘은 패스`(확인 후 건너뜀), `10분 후 다시 묻기`(1회).
- Android 작은 아이콘 `@drawable/ic_stat_duodone`, 채널 4종(리마인더·일반·예약·디버그) 이름·설명 현지화. 백그라운드 isolate에서 만든 문자열은 설정 언어가 아니라 기기 언어를 따른다.

## 2. 원격 알림 (FCM, Cloud Functions Node 22)
| `data.type` | 트리거 | 수신자 | 비고 |
|---|---|---|---|
| `plan_proposed` | `onPlanCreated` | 짝꿍 | `🤙 {이름} 운동 약속 걸었어` + `🏋️ 헬스 · 월·수·금 21:00까지 · 봐줄 거지? 👀`. 레거시 pending은 `확인해 줄래?` |
| `action_completed` | `onActionCompleted` (done·skipped·rested) | 짝꿍 | 신규 키 `actionId`, `hasProof`. 인증샷 문구(`📸 {이름} 오운완 인증샷 도착!` / `… 인정해 줄래?`)는 `proofPhotoPath`가 있고 **수신자 `clientBuild` ≥ 81**일 때만. `rescued`는 더 이상 푸시 안 함 |
| `cheer` | `onCheerCreated` (이모지) | 실행자 | 오늘 `completedDates`가 있으면 `인정`, 없으면 `응원` 문구 |
| `poke` | `onCheerCreated` (`poke`) / `onPlanUpdated` (`lastPokeAt`) | 실행자 | 약속당 하루 1회 서버 제한(`serverLocks`). `실천 메이트` 포함 저장 문구는 새 기본 문구로 대체 |
| `poke_reply` (신규) | `onCheerCreated` (`reply`) | 짝꿍 | `💬 {이름}의 답장` + 답장 문구. `planId`, `senderName`, `message` |
| `action_missed` | `notifyMissedActions` (30분 주기) | 짝꿍 | 마감 + 30분 유예, 실행자 시간대 기준, 약속당 하루 1회 |
| `verify_reminder` | `notifyUnverifiedActions` (60분 주기) | 짝꿍 | 24~72시간 동안 인정 안 된 done 1회(`verifyReminderSentAt`). **수신자 현지 09:00~22:00에만** |
| `action_verified` | `onPlanUpdated` (`verifiedDates` 증가, cheers 없음) | 실행자 | 기록 탭 인정 등 |
| `plan_approved` / `plan_rejected` / `plan_updated` | `onPlanUpdated` | 상대 | 레거시 승인·조율·변경 |
| `partner_connected` (신규) | `onRelationCreated` | 초대자 | `partnerId`, `senderName`. 1건만 |
| `partner_connect_failed` (신규) | `onRelationCreated` | 코드 입력자 | `reason: owner_taken|self_taken|invalid_code` |

### 중복·오발송 방지
- **인정 1건 = 푸시 1건**: 같은 업데이트에서 `verifiedDates`가 늘고 `lastCheerAt`도 바뀌면 `onPlanUpdated`는 침묵하고 `onCheerCreated`가 보낸다. cheers 없이 인정하면(`verifyPlan`, `verifyHistoryItem`) `onPlanUpdated`가 `action_verified`를 보낸다.
- `lastUpdatedBy`가 `system_`으로 시작하면(`system_link`, `system_unlink`, `system_missed_action`) 푸시하지 않는다.
- 연결되지 않은 사용자 사이의 푸시는 버린다(트리거마다 relation 확인).
- 에뮬레이터(`FUNCTIONS_EMULATOR=true`)에서는 FCM 대신 `emulatorPushes`에 기록한다.

### 시간대
- 마감 판정·하루 1회 기준일은 실행자 `users.timezone`(IANA, 없으면 `Asia/Seoul`). 예: LA 21:00 마감 → LA 21:30 이후 판정.
- 앱은 로그인 시 `users.clientBuild`·`timezone`·`locale`을 바뀐 값만 기록한다(`ClientMetadataSync`).

## 3. 앱 쪽 푸시 처리
- 탭 시 `notification_opened {type, cold_start}` 기록.
- 처리 대기(후속): `partner_connected` → 애칭 시트 또는 우리 탭, `poke_reply` → 약속, `partner_connect_failed` → 사유 안내 후 재입력, `action_completed`의 `actionId`/`hasProof` → 사진 딥링크. 지금은 앱만 연다.

## 수명주기 (변경 없음)
| 이벤트 | 동작 |
|---|---|
| 약속 생성 | 마감 시각으로 예약 |
| 약속 수정 | 기존 취소 → 재예약 |
| 오늘 기록 | 오늘 알림 제외(skipToday) |
| 완료·중단·삭제 | 관련 알림 취소 |
| 회원 탈퇴 | 전부 취소 |

## 권한
- Android 13+: 알림 권한, `SCHEDULE_EXACT_ALARM`. iOS: Alert·Badge·Sound. 첫 알림 설정 시점에 요청하고, `runApp` 전에는 요청하지 않는다(Play 로딩 반려 대응).
- 거부 시 FCM 토큰 정리, 지금 탭 상단 권한 배너.

## 알려진 한계
- 예약 함수(`notifyMissedActions`, `notifyUnverifiedActions`)는 Pub/Sub 에뮬레이터 없이 단위 테스트만 했다. 배포 후 로그로 확인.
- 이번 functions 배포로 모든 사용자에게 즉시 바뀌는 것: 연결 안 된 사용자 간 푸시 차단, rescued 무푸시, 인정 리마인더 09~22시, 연결·해제 때 코드 회전, 짝꿍 없어지면 애칭 삭제.
