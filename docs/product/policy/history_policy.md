<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 히스토리(History) 정책

## 개요
플랜 실천 기록을 추적하고, 파트너와의 확인/피드백을 관리하는 기능.

## 히스토리 항목 구조

### HistoryItem 모델
- `id`: 고유 식별자
- `planId`: 연관 플랜
- `date`: 실천 날짜
- `title`: 실천 내용
- `status`: 상태 (아래 참고)
- `executorId`: 실천자
- `note`: 실천자 메모
- `comment`: 매니저 피드백
- `isVerifiedByPartner`, `isVerifiedByMe`: 확인 플래그
- `partnerName`, `partnerImageUrl`, `partnerMessage`: 파트너 정보

## 히스토리 상태

| 상태 | 한글 | 설명 |
|------|------|------|
| `done` | 했어 | 당일 실천 완료 |
| `actuallyDone` | 사실 했어요 | 사후 정리 - 실제로 했다고 정정 |
| `rested` | 쉴게요 | 사후 정리 - 쉬었다고 정정 |
| `verified` | 확인됨 | 매니저가 실천 확인 |
| `skipped` | 건너뜀 | 당일 건너뜀 |

## 화면 구성

### 섹션 구분
1. **진행 중 플랜 섹션**: 현재 활성 약속과 최근 실천 기록
2. **완료된 플랜 섹션**: 완료/중단된 플랜 요약

### 그룹핑
- 플랜/행동별 그룹
- 날짜별 정렬 + 리액션 포함

## 카드 유형

### HistoryCard
- 개별 실천 기록 표시
- 리액션 아이콘 포함

### PlanSummaryCard
- 완료된 플랜 통계 표시
  - 총 약속 일수
  - 달성률
  - 최종 상태

## 사후 정리 (Reconciliation)

### 목적
과거 실천에 대한 이견 해소

### 프로세스
1. 매니저가 과거 기록에 의문 제기
2. 실천자가 해명:
   - "사실 했어요" → `actuallyDone`
   - "쉬었어요" → `rested`
3. 상태 업데이트

## 리액션 시스템
- 이모지 종류: fire, heart, thumbs_up, muscle
- 히스토리 항목 하단에 표시
- 저장 위치: 히스토리 항목 레코드 내

## 실시간 업데이트
- `getHistoryItemsStream()`으로 Firestore 변경 감지
- 파트너의 리액션/확인 추가 시 자동 갱신
