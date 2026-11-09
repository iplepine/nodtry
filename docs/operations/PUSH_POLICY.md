# 푸시 정책 (일일 상한 · ko/en 문구)

마지막 갱신: 2026-11-09 (다음 릴리스 1.2.0+88과 함께 functions 배포). 서버 변경이라 **functions 배포 즉시 모든 사용자(구버전 포함)에게 적용**된다. 앱 변경 없음.

관련 코드: `functions/src/pushPolicy.ts`(순수 정책), `functions/src/index.ts` `sendCopy`(유일한 FCM 발송 경로), `functions/src/copy.ts`(ko/en 문구). 테스트: `functions/test/pushPolicy.test.js`, `functions/test/copyEn.test.js`, `rules-tests/test/firestore.test.js`(pushQuota 차단), `rules-tests/functions/triggers.test.js`(에뮬레이터 상한·영어).

## 1. 발송 경로 인벤토리
모든 원격 푸시는 `sendCopy` → `sendAndCleanup` → `admin.messaging().send` 한 길로만 나간다(다른 `messaging()` 호출 없음).

| `data.type` | 발송 위치 | 등급 | 출처 제한(기존) |
|---|---|---|---|
| `partner_connected` | `announceLink` → `sendConnectPush` | core | 수신자당 하루 5건(`connect_push_*`) |
| `partner_connect_failed` | `undoLink` → `sendConnectPush` | core | 같음 |
| `action_completed` (done) | `onActionCompleted` | core | 기록 1건당 1건 |
| `action_completed` (skipped·rested) | `onActionCompleted` | standard | 기록 1건당 1건 |
| `cheer` — 그날 첫 인정(오늘 기록이 있는 날의 리액션) | `onCheerCreated` | core | **약속당 수신자 현지 하루 1건**(`verify_core_{planId}_{day}`, `action_verified`와 공유) |
| `cheer` — 그 뒤 인정·응원(그 외) | `onCheerCreated` | secondary | 발신→수신 시간당 20건 |
| `action_verified` — 그날 첫 인정 | `onPlanUpdated` | core | 약속당 수신자 현지 하루 1건(위 lock 공유) |
| `action_verified` — 그 뒤 인정 | `onPlanUpdated` | standard | 이벤트당 1건 |
| `poke_reply` — 오늘 받은 똑똑에 대한 첫 답장 | `onCheerCreated` | core | **그날 똑똑 lock(`poke_plan_*`/`poke_pair_*`)이 있을 때만, 약속(또는 쌍)당 하루 1건**(`reply_core_*`) |
| `poke_reply` — 똑똑 없는 답장·두 번째 이후 답장 | `onCheerCreated` | standard | 발신→수신 시간당 20건 |
| `poke` | `onCheerCreated` / `onPlanUpdated` | standard | 약속(또는 쌍)당 수신자 현지 하루 1건 |
| `action_missed` | `notifyMissedActions` | core | 약속당 하루 1건 |
| `verify_reminder` | `notifyUnverifiedActions` | secondary | done 1건당 1회, 수신자 현지 09–22시 |
| `plan_proposed` — 그날 3건까지 | `onPlanCreated` | core | **발신→수신 수신자 현지 하루 3건**(`plan_proposed_core_*` 토큰, `PLAN_PROPOSALS_CORE_PER_DAY`) |
| `plan_proposed` — 4건째부터 | `onPlanCreated` | standard | 약속 생성당 1건 |
| `plan_approved` / `plan_rejected` | `onPlanUpdated` | core | 레거시 pending → 결정 변경 1회당 1건 |
| `plan_updated` | `onPlanUpdated` | standard | **신규: 같은 약속·수신자 15분 내 1건으로 합침** |
| (모르는 타입) | — | secondary | — |

마감 리마인더(내 약속 마감)는 서버 푸시가 아니라 앱 로컬 알림이라 상한 대상이 아니다.

## 2. 일일 상한
- 기준일: **수신자** 현지 날짜(`users/{uid}.timezone`, 없거나 잘못되면 `Asia/Seoul`).
- 카운터: `pushQuota/{uid}_{YYYYMMDD}` `{count, core, standard, secondary, suppressed, updatedAt, expireAt}` — 트랜잭션으로 읽고 갱신. `count`는 실제로 내보낸 푸시 수(모든 등급 포함), `suppressed`는 상한으로 버린 수.
- 결정(`quotaDecision`):
  - **core**: 항상 보낸다(카운트만 올림).
  - **standard**: 오늘 `count < 8`(`DAILY_PUSH_CAP`)일 때만.
  - **secondary**: 오늘 `count < 5`(`SECONDARY_PUSH_LIMIT`)일 때만.
- 왜 8/5인가: 보통 커플의 하루는 한 사람당 2–5건(짝꿍 인증샷, 내 기록 인정, 가끔 미기록 알림·똑똑·답장). 응원·리마인더 같은 부가 푸시는 5건에서 멈춰 최소 3칸을 핵심 루프에 남기고, 정보성(standard)은 8건에서 멈춘다. 핵심 루프(spec §4: 인증샷 → 인정, 안 하면 짝꿍이 안다, 똑똑 답장, 연결)는 빠지면 제품이 깨지므로 상한으로 막지 않는다. 대신 **core는 루프에 꼭 필요한 그 1건에만** 붙고 모두 작은 출처 제한이 있다(위 표): 같은 약속의 두 번째 인정, 똑똑 없이 온 답장, 하루 4번째 약속 제안은 core가 아니라 상한을 따른다. 그래서 수다스러운(또는 변조된) 클라이언트가 core로 상한을 넘길 수 없다.
- core 판정용 lock/토큰(`verify_core_*`, `reply_core_*`, `plan_proposed_core_*`)은 `serverLocks`(기존 TTL `expireAt` 3일)에 둔다. lock 처리에 실패하면 그 푸시는 core만 잃고(상한 적용) 버려지지는 않는다.
- 상한으로 버리면 로그 `Push suppressed: daily cap (to=…, type=…, tier=…, sentToday=…, day=…)`(info). 합친 경우 `Push to … coalesced (plan_updated)`.
- 버린 `verify_reminder`는 "보내지 않음"으로 처리돼 `verifyReminderSentAt`이 찍히지 않고, 72시간 창 안에서 다음 시간대 실행(대개 다음 현지일)에 다시 시도된다.
- FCM 발송이 실패하면 카운트를 1 되돌린다(재시도가 두 번 세지지 않게). 쿼터 트랜잭션 자체가 실패하면 **보낸다**(fail-open, 경고 로그).
- 조정: 상수는 `functions/src/pushPolicy.ts`. 바꾸면 functions 재배포.

## 3. 문구 언어 (ko/en)
- 수신자 `users/{uid}.locale`가 `en`(또는 `en-*`, `en_*`)이면 영어, 그 외·없음은 한국어(`langOf`). 앱은 로그인 시 `ko|en`을 기록한다(`ClientMetadataSync`).
- 짝꿍 호칭: 애칭(`partnerNickname`) → 표시 이름 → `짝꿍` / `your partner`(문장 첫머리면 `Your partner`). 애칭·이름은 사용자가 쓴 그대로.
- 영어 용어는 앱 en ARB와 같다: 약속 promise, 인정 props, 똑똑 knock, 휴식권 rest pass, 인증샷 proof photo. 운동 이름은 문장용 소문자(`today's run`).
- 공통 규칙 유지: 앱 이름(둘운완/DuoDone) 미포함, `님` 금지, 감시 뉘앙스 금지(monitor/watch/check on 없음), `workoutType` 없으면 중립 `promise` 문구, 식단은 workout 단어 없음.
- 짝꿍이 직접 쓴 문구(똑똑·답장·한마디)는 원문 그대로 전달한다. 서버 기본 문구(빈 똑똑·레거시 `실천 메이트` 대체)만 수신자 언어로 바뀐다.
- `data.type`, `data.category`(`partner_proof`/`poke_reply`/`partner_missed`), 버튼 식별자는 바뀌지 않는다. **버튼 제목은 서버가 아니라 앱이 정한다**(iOS 카테고리 등록·Android 데이터 전용 푸시 모두 `lib/services/notification_quick_actions.dart` + 앱 l10n) — 서버 쪽에서 현지화할 버튼 문구는 없다.
- `data.senderName`, `data.itemTitle`(제목 없는 레거시 항목의 `today's promise` 등)도 수신자 언어를 따른다.

## 4. 데이터·규칙
- `pushQuota`는 서버 전용. `firestore.rules`(와 `.next`)에 match가 없어 클라이언트 read/write 전부 거부(기본 거부). 규칙 테스트로 고정.
- `expireAt` = 쓰기 시각 + 3일. TTL 정책으로 자동 삭제(`firestore.indexes.json` `fieldOverrides`에 추가).

## 5. 배포 단계 (대표 승인 후)
1. `firebase deploy --only firestore:indexes --project nod-try` — `pushQuota.expireAt` TTL 포함. 파일에 없는 콘솔 인덱스를 지우겠냐고 물으면 **No**.
   - 또는 직접: `gcloud firestore fields ttls update expireAt --collection-group=pushQuota --enable-ttl --project=nod-try`
   - 확인: `gcloud firestore fields ttls list --project=nod-try`
2. `firebase deploy --only functions --project nod-try`.
3. 규칙은 주석만 바뀌어 재배포 불필요(배포해도 무해).
4. 배포 후 로그 확인: `Push suppressed: daily cap` 빈도, `Push quota check failed`가 없는지.
