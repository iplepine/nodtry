<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (37 files)`
> - 문서 갱신: `2026-10-03 07:19:00 +0900`
<!-- COMMIT_STATUS END -->

# 똑똑(Poke)·응원 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S2·S6·backend)

## 개요
**안 하면 짝꿍이 안다**를 가볍게 만드는 장치다. 짝꿍은 놓친 운동에 `응원 보내기`(주)나 `똑똑`(보조)을 보내고, 받은 쪽은 한 번 탭으로 답한다. 감시가 아니라 "봐준다"는 톤을 지킨다.

## 똑똑 유형
### 1. 약속 똑똑 (`partnerPoke`)
- 조건: 짝꿍에게 오늘 예정·미기록 약속이 있다.
- 기본 문구(저장값): `똑똑! 오늘 약속 기다리고 있어` (`kDefaultPlanPokeMessage`). 화면은 보내는 사람 언어로 현지화된 문구를 넘긴다.
- **제한**: 약속당 수신자 현지 날짜 기준 하루 1회. 서버가 `serverLocks`로 강제한다(plan의 `lastPokeAt` 경로와 cheers 경로 공유). 앱은 오늘 이미 보냈으면 버튼을 `오늘 똑똑 보냈어요`로 끈다.

### 2. 약속 없음 똑똑 (`partnerNoPlan`)
- 기본 문구: `똑똑! 운동 약속 하나 걸어 줘` (`kDefaultUserPokeMessage`). planId 없는 cheers는 짝꿍 쌍당 하루 1회 제한.

### 3. 놓친 운동 자동 전달 (`action_missed`)
- 조건: 짝꿍 있는 active 약속, 오늘 예정, 마감 + 30분 유예가 지남, 오늘 done/skip/rest/rescue 없음. 판정은 **실행자 `users.timezone`** 기준(없으면 Asia/Seoul).
- `notifyMissedActions` 30분 주기 → 실제 전달은 마감 후 30~60분. 사용자 문구에 정확한 분을 약속하지 않는다.
- 같은 약속 하루 1회. `lastMissedNotifiedAt`, `lastUpdatedBy: system_missed_action`.
- 짝꿍 카드는 `응원 보내기`(주) / `똑똑`(보조) 순서.

## 응원 보내기
- `cheers {fromUserId, toUserId, planId?, reactionType: '💪', message: '할 수 있어! 기다릴게 💪'}`
- 인정이 아니다: `verifiedDates`를 건드리지 않고, 서버는 오늘 기록이 없으므로 `응원` 문구로 보낸다.
- 분석: `cheer_sent {surface: missed_card, has_message}`

## 받은 쪽 원탭 답장
- 조건: 오늘 똑똑을 받았고 아직 기록이 없다.
- 버튼: `지금 간다 🏃` / `오늘은 봐줘 🙏`
- 저장: `cheers {fromUserId, toUserId: plan.managerId, planId, reactionType: 'reply', message, createdAt}`. 약속 문서는 안 바꾼다.
- 서버: `onCheerCreated` → 푸시 `💬 {이름}의 답장`, `data.type = poke_reply`.
- 기기별로 약속·날짜당 1회 기억(`poke.replied_v1`). 다른 기기에서는 버튼이 다시 보일 수 있다.
- 분석: `poke_replied {kind: coming|pass}`

## 호환
- 구버전이 저장한 `실천 메이트` 포함 똑똑 문구는 서버(푸시)와 앱(`pokeHeaderFor`) 모두 새 기본 문구로 바꿔 보여 준다. 그 외 옛 문구는 그대로 표시된다.
- 연결되지 않은 사용자 사이의 cheers는 푸시하지 않는다.

## 구현 위치
- 카드 규칙: `now_card_rules.dart` `knockedToday`, `showsPokeReplies`, `leadsWithCheer`
- 저장: `RealRecordRepository.replyToPoke`, `sendCheer`, `pokeUser`/`pokePartner`
- 서버: `functions/src/index.ts` `onCheerCreated`, `onPlanUpdated`, `notifyMissedActions`; 문구 `copy.ts`

## 알려진 한계
- 똑똑을 보낸 직후 짝꿍 카드는 예전처럼 사라진다. 비활성 상태는 주로 스트림에 오늘 똑똑이 이미 있을 때 보인다. 실제 가드는 서버 제한이다.
