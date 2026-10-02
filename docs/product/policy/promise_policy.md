<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 내기(Promise) 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S2·S6) · 사용자 용어 `내기`(지키면 / 못 지키면), 코드·데이터 `promise`(reward / penalty)

## 개요
운동 약속에 짝꿍끼리 비금전 내기를 건다. 예: `못 지키면 🍗 치킨 쏘기`, `지키면 🍣 같이 오마카세`. 정산 로직은 피벗 전과 같다.

## 원칙
- **비금전만.** 돈이 오가는 내기는 지원하지 않는다(Pact가 FTC와 합의해 환불한 사례 `Evidence`, `RESEARCH_LOG.md` #22).
- 앱 문구는 `보상/벌칙` 대신 `지키면 / 못 지키면`을 쓴다.

## Promise 모델
- `reward`(지키면): 설명 + 달성 기준 일수 · `penalty`(못 지키면): 설명 + 발동 기준 일수
- `proposerId`, `status`, `settlementAcknowledgedBy`
- 상태 값(`proposed|active|settled|rejected`)은 추가하지 않는다.

## 상태 흐름
```
proposed ─수락→ active ─약속 종료→ settled
   └─거절→ rejected
```
- 짝꿍 연결이 끊기면 서버(`onRelationDeleted`)가 진행 중(proposed/active) 내기를 `rejected`로 바꾼다.

## 내기 시트
- **못 지키면이 먼저, 기본 켜짐.** 지키면은 선택.
- 못 지키면 칩: 🍗 치킨 쏘기 · ☕ 아아 쏘기 · 🍽️ 설거지 일주일 · 💆 마사지 10분 · 🎬 영화 고르기 권한 · 🚗 데리러 가기
- 지키면 칩: 🍣 같이 오마카세 · 🍰 디저트 데이트 · 💆 마사지 10분 받기 · 🎬 영화 고르기 권한
- 직접 입력 가능. 짝꿍 카드의 `내기 걸기`나 똑똑과 함께 제안한다.

### 돈 가드 (`mentionsMoney`)
- `만원`, `₩`, `현금`, `송금`, `계좌`, `포인트`(및 일부 영어 돈 단어)는 어디에 있든 차단.
- `원`은 숫자나 한국어 수사 뒤에 올 때만 돈으로 본다(`3000원`, `5천 원`, `오천원`). `소원 들어주기`, `공원`, `병원`, `원샷`은 허용. 스펙의 문자 그대로 정규식과 의도적으로 다르다.
- 걸리면 필드 오류 `돈 내기는 지원하지 않아요. 밥, 커피, 설거지처럼 둘이 할 수 있는 걸로 걸어 주세요.`로 안내하고 저장을 막는다. 드물게 `사원`·`구원`·`일원` 같은 단어가 막힐 수 있다.

## 제안 화면 기준 (피벗 전과 같음)
- 약속 전체 기간과 정산 기준 예정일 수를 함께 보여 준다.
- 지키면 일수는 `현재 성공일 + 남은 예정일` 안에서, 못 지키면 일수는 `현재 실패일 + 남은 예정일` 안에서만 조절한다.
- 기본값은 상한에 붙이지 않는다. 저장 시 도달 불가능한 `targetDays`는 거부한다.

## 진행 중 칩 (지금 탭)
`status == active` 동안 실행자 카드 액션 버튼 위에 한 줄 칩.
1. 못 지키면 확정 → 2. 못 지키면 임박(여유 ≤1) → 3. 지키면 달성 → 4. 지키면 임박(≤2일) → 5. 양쪽 여유 → 6. 한쪽만
- 성공일 = `completedDayCount()`, 남은 예정일 = `remainingScheduledDayCount()`
- 칩 탭 → 조건 바텀시트(성공/실패/남은 일수, 각 진행 바)

## 정산
- 약속 `completed`/`stopped` 시 `completedDates` 기준으로 계산: `rewardAchieved` / `penaltyTriggered` / `bothMet` / `neitherMet`
- 양쪽에 `promiseSettled` 카드. `결과 확인하기` → `settlementAcknowledgedBy`에 본인 추가, 한마디는 `lastComment`/`lastCheerAt`으로 전달.
- 정산은 `completedDates` 기준이다(인정 여부 무관). `verifiedDates` 기준·쿠폰·서버 정산은 다음 릴리스 후보.
