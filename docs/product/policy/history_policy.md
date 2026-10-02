<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 기록(History) 탭 정책

마지막 갱신: 2026-10-03 (1.1.0+81)

## 개요
나와 짝꿍의 운동 기록·인증샷·인정을 날짜순으로 본다. 탭 이름은 `기록`(EN History).

## HistoryItem (원천: `actions/{id}`)
- `id`, `planId`, `date`, `title`, `status`, `executorId`, `note`(실행자 메모), `comment`(짝꿍 한마디)
- `isVerifiedByPartner` / `isVerifiedByMe`, `partnerName`, `partnerImageUrl`, `partnerMessage`
- 신규: `proofPhotoPath`, `proofSource`(`camera|gallery`), `proofTakenAt`, `reaction`(짝꿍이 인정한 이모지)

## 상태
| 상태 | 표시 | 설명 |
|---|---|---|
| `done` | 했어 | 오운완 기록 |
| `verified` | 인정받음 | 짝꿍이 인정 |
| `rested` | 쉬었어 | 휴식권 |
| `skipped` | 건너뜀 | 오늘 건너뜀 |
| `actuallyDone` | 사실 했어 | 레거시 사후 정리 |

action type 값은 추가하지 않는다.

## 화면 구성
- **주간 펄스 카드**: 이번 주 둘운완 일수와 나/짝꿍 도트. 지금·우리 탭과 같은 `duoStatsProvider`를 쓴다.
- **기록 카드**: 인증샷 썸네일 + 출처 배지, 메모, 리액션 아이콘.
  - 짝꿍 기록이 아직 인정 전이면 ❤️🔥💪👏 리액션 줄 + `한마디`. 탭하면 `HistoryIntent.verify(id, reaction:)` → `verifyHistoryItem`이 `actions.reaction`·`verifiedDates`·`lastUpdatedBy`(=인정한 사람)를 쓴다.
  - 인정된 기록은 리액션 아이콘 표시.
- 사진 탭 → 전체 화면 보기(신고·연결 끊기·본인 삭제). [proof_photo_policy.md](./proof_photo_policy.md)
- 필터와 짝꿍 이름은 `partnerLabelProvider`(애칭 우선).
- 오류는 `historyErrorUnknown`으로 표시(원문 예외 노출 금지). 제목 없는 기록은 `약속`(`promiseUntitledFallback`).

## 푸시
- 기록 탭 인정은 cheers 문서를 만들지 않으므로 `onPlanUpdated`가 `action_verified` 1건만 보낸다(이모지 미포함).

## 사후 정리 (레거시)
- 짝꿍이 과거 기록에 의문을 제기하면 실행자가 `사실 했어` / `쉬었어`로 정정하는 흐름이 남아 있다. 신규 기능 확장 대상은 아니다.

## 실시간
- `getHistoryItemsStream()`으로 Firestore 변경을 반영한다. 짝꿍의 리액션·인정이 바로 보인다.
- 짝꿍의 모든 약속을 `userId`로 읽는다(둘운완 통계와 같은 쿼리). plans read 규칙을 좁히면 이 쿼리 전체가 거부되므로, 보안 묶음 때 쿼리를 함께 바꿔야 한다.
