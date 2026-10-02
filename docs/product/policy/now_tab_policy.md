<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (35 files)`
> - 문서 갱신: `2026-10-03 07:18:59 +0900`
<!-- COMMIT_STATUS END -->

# 지금 탭(Now Tab) 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S1·S4·S5·S6)

## 개요
지금 탭의 역할은 하나다: **오늘 운동했어?**에 답하게 하고, 짝꿍의 오운완을 인정하게 한다.
카드 판단 로직은 `cards/now_card_rules.dart`의 순수 함수에서만 한다. 번역 문자열(`headerMessage`, 시간 칩 텍스트) 비교로 분기하지 않는다(피벗에서 제거).

## 헤더
- 짝꿍이 있으면 **둘운완 헤더**: 두 아바타 + `둘이 함께 N일째`(0이면 `오늘 둘 다 하면 둘운완 1일째`) + 각자 상태 칩(예: `나 인정 대기` / `{애칭} 아직`). 오늘이 둘운완 데이면 `오늘 둘운완이에요 🎉`. 계산은 [duo_stats_policy.md](./duo_stats_policy.md).
- 짝꿍이 없거나 통계가 아직 없으면 기존 조용한 헤더.
- 상대 이름은 `partnerLabelProvider`(애칭 → 표시 이름 → `짝꿍`).

## 카드 유형

### 내 카드
| 상태 | 설명 |
|---|---|
| `nowAction` / `nextAction` / `overdue` | 오늘 예정 약속. 오늘 미기록이면 **오늘 운동했어? 히어로**로 렌더 |
| `poked` | 짝꿍이 똑똑함. 히어로 + 똑똑 배지 + 원탭 답장 |
| `todayComplete` | 오늘 다 함. 내 인증샷 썸네일 + `짝꿍이 인정했어요`(리액션) |
| `todayEmpty` / `emptyPlan` | 오늘 예정 없음 / 약속 없음(생성 유도) |
| `promiseProposed` / `promiseSettled` | 내기 제안 받음 / 내기 정산 |
| `pilotSettlement` | 28일 종료 약속의 4주 정산(다음 4주 의향) |
| `rejected` | 레거시 조율 요청 |

### 짝꿍 카드
| 상태 | 설명 |
|---|---|
| `partnerAction` | 짝꿍이 오늘 기록함. 인증샷·메모 + ❤️🔥💪👏 리액션 줄 |
| `partnerPoke` | 짝꿍 미기록. 놓친 운동 자동 전달 버전이면 `응원 보내기`(주) / `똑똑`(보조) |
| `partnerNoPlan` | 짝꿍 약속 없음. 똑똑으로 약속 걸자고 부른다 |
| `partnerPlanCreate` / `partnerPlanModify` | 레거시 승인 대기 약속. 승인 버튼만 노출 |
| `partnerPromiseProposed` | 내가 낸 내기 제안 대기 |

### 초대 카드
- 짝꿍이 없으면 `NowInviteCard`. 초대를 공유한 뒤에는 `짝꿍을 기다리는 중이에요` + `초대 다시 보내기`.

## 오늘 운동했어? 히어로
- 노출: `showsTodayCheckInHero(state, plan, now)` — nowAction·nextAction·overdue 카드가 **오늘 예정이고 done·skip·rest 기록이 없으면 하루 종일**, poked 카드는 기록이 없으면. 22:00 마감 약속도 09:00부터 보인다(`isDueNowItem`은 그대로).
- 질문(`todayCheckInQuestion`): 운동 `오늘 🏃 러닝 했어?`, 식단 `오늘 🥗 식단 지켰어?`, 레거시 `오늘 '{title}' 했어?`
- 버튼: `📸 인증샷 찍기`(주) → [proof_photo_policy.md](./proof_photo_policy.md) / `사진 없이 했어`(메모 다이얼로그) / `오늘은 쉴게`(휴식권이 남아 있을 때). 휴식권이 없는 overdue 카드는 기존 건너뛰기 링크.
- 레거시 약속도 같은 📸 / 사진 없이 버튼을 쓴다(스펙의 단일 `인증하기` 대신. 의도적 차이).

## 짝꿍 쪽 동작
| 동작 | 결과 |
|---|---|
| 리액션 원탭(❤️🔥💪👏) | 오늘 done action에 `reaction`, plan `verifiedDates`에 오늘. 다이얼로그 없음 |
| `한마디` | 메모와 함께 ❤️ 전송 |
| `응원 보내기`(놓친 운동) | `cheers {reactionType: '💪', message: '할 수 있어! 기다릴게 💪'}`. **인정 아님**(`verifiedDates` 안 건드림) |
| `똑똑` | 약속당 하루 1회. 오늘 이미 보냈으면 `오늘 똑똑 보냈어요`로 비활성 |
| `내기 걸기` | [promise_policy.md](./promise_policy.md) |
| 레거시 승인 | pending일 때만 기간 리셋 후 active |

- 오늘 인증샷 판정: `lastProofAt`이 오늘이고 경로가 `lastActionId`와 맞을 때만. 어제 사진은 오늘 인증으로 보이지 않는다.

## 똑똑 받은 쪽
- 오늘 똑똑을 받았고 미기록이면 `지금 간다 🏃` / `오늘은 봐줘 🙏` 원탭 답장. `cheers {reactionType: 'reply'}`만 쓰고 약속은 안 건드린다. 기기에서 약속별·날짜별로 답장 여부를 기억한다.
- 카드를 보면 `lastPokeAcknowledgedAt`이 자동 기록된다.

## 홈 프롬프트 (한 번에 하나, 홈이 최상단일 때만)
1. 기존 사용자 1회 공지 → 2. 첫 로그인 클립보드 초대 코드 확인(1회) → 3. 애칭 시트(짝꿍당 1회) → 4. 둘운완 순간(공유 카드·평점 요청)

## 숨김
- 집중 타이머 버튼(`_kFocusTimerEnabled=false`), 어제 인정 rescue 버튼(`_kRescueButtonEnabled=false`), 기록 응시(record gaze) 팁(삭제)

## 4주 정산
- 28일 완료 약속 중 `pilotNextPlanIntent`가 없으면 `pilotSettlement` 카드. `다음 4주 시작하기`(같은 약속 새 28일) / `여기서 마무리`(사유 기록). 필드명은 레거시 `pilot*` 유지.
