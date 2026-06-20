<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `d591e92e08aca84dcec3c09187fb4ab615b1419d` (`main`)
> - 최근 커밋: `d591e92e08ac` chore: bump version to 1.0.53+75 (now-tab timing & carousel swipe)
> - 커밋 일시: `2026-06-16T10:09:48+09:00`
> - 워킹트리: `dirty (64 files)`
> - 문서 갱신: `2026-06-20 22:33:15 +0900`
<!-- COMMIT_STATUS END -->

# Task

ID: `NT-001-study-sprint-thin-slice`

유형: `Spec`

상태: `Done`

연결 Roadmap: `R-001-study-sprint-prep`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-05-03

## 목표

현재 앱이 `스터디 템플릿 -> 파트너 연결 -> 확인/응원 -> 4주 정산` 파일럿 흐름을 어디까지 지원하는지 대조하고, 빠진 구현만 다음 task로 분리한다.

## 배경

Nodtry는 이미 1:1 파트너, 플랜, 확인, 똑똑, 약속 구조가 있다. 새 기능을 크게 만들기 전에 파일럿에 필요한 얇은 흐름만 확인해야 한다.

## 범위

포함:

- 현재 플랜 생성 흐름과 스터디 템플릿 요구사항 대조
- 파트너 확인/응원/똑똑 흐름 확인
- 4주 정산 가능 여부 확인
- 필요한 `Build` task 분리

제외:

- 실제 결제 구현
- 공개 랭킹
- 공부 타이머
- AI 코치

## 완료 기준

- [x] 현재 지원되는 흐름과 빠진 흐름 목록 작성
- [x] 필요한 구현 task가 1-3개로 분리됨
- [x] 테스트 또는 검증 완료
- [x] 관련 문서 업데이트
- [x] 남은 리스크 기록

## Thin Slice 대조 결과

| 순서 | 파일럿 흐름 | 현재 판단 | 근거 | 후속 |
|---:|---|---|---|---|
| 1 | 스터디 템플릿 선택 | `Supported` | 플랜 생성 첫 단계에 영어/자격증/코딩/독서/글쓰기 템플릿 추가 | `BT-001` 완료 |
| 2 | 기본 빈도/알림 자동 입력 | `Supported` | 기본 주 3회/21:00, 템플릿별 주 3회 또는 주 5회/21:00 적용 | `BT-001` 완료 |
| 3 | 파트너 초대 코드 공유 | `Supported` | 프로필/연결 화면에서 초대 코드 입력과 연결 처리 지원 | 파일럿 안내 문구 필요 |
| 4 | 파트너 승인 또는 조율 | `Supported` | `pending_approval`, `approvePlan`, `rejectPlan` 흐름 존재 | 첫 주 노출 강화 필요 |
| 5 | 오늘 실천 완료 | `Supported` | `nowAction`, `reportCompletion`, 히스토리 기록 존재 | 시나리오 테스트 유지 |
| 6 | 파트너 확인/응원/똑똑 | `Partially supported` | 확인, 응원, 똑똑, missed 알림은 있으나 첫 주 압박감과 가시성이 약함 | `BT-002` |
| 7 | 지연 시 조율 | `Partially supported` | 반려/조율, 휴식, 구제는 있으나 파일럿용 지연 안내가 약함 | `BT-002` |
| 8 | 4주 종료 정산 | `Partially supported` | 약속 정산 로직은 있으나 파일럿 지표 카드와 재참여 질문이 없음 | `BT-003` |
| 9 | 다음 플랜 생성 또는 종료 사유 기록 | `Missing` | 다시 시작은 가능하지만 재참여 의향/종료 사유 수집이 없음 | `BT-003` |

## 분리한 Build Tasks

1. `BT-001-study-template-defaults`: 스터디 템플릿, 기본 주 3회/5회, 21:00 알림, 28일 저장 기본값.
2. `BT-002-partner-pressure-visibility`: 파트너 확인/응원/똑똑/놓친 약속이 첫 주에 묻히지 않도록 Now 탭 가시성 강화.
3. `BT-003-four-week-settlement`: 4주 완료 일수, 파트너 피드백 수, 다음 4주 의향, 종료 사유를 회수하는 임시 정산 화면.

## 검증 결과

명령:

- `flutter test test/viewmodels/plan_create_viewmodel_test.dart --reporter expanded`
- `flutter test --reporter expanded`

결과:

- 스터디 기본값, 템플릿 적용, 28일 저장/알림 예약 테스트 통과.
- 전체 Flutter 테스트 통과.

## 남은 리스크

- 파트너 압박이 실제로 행동을 당기는지, 부담만 주는지는 파일럿에서 별도 질문으로 확인해야 한다.
- 4주 정산은 약속 정산과 파일럿 지표 정산이 섞여 있어, 사용자에게 보여줄 카드와 운영자가 회수할 지표를 분리해야 한다.
- 기존 문서 일부는 "상호 지지" 톤이 강하므로 첫 주 압박 UX를 만들 때 문구 기준을 다시 맞춰야 한다.

## 후속 task

- `BT-002-partner-pressure-visibility`
- `BT-003-four-week-settlement`
