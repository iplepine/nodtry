<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 작업 관리

마지막 갱신일: 2026-10-03

## 현재 집중

현재 active goal: [`G-002-duounwan-launch`](./goals/active/G-002-duounwan-launch.md) — 둘운완 1.1.0(81) 동시 공개, iOS 건강 및 피트니스 Top 10 진입

현재 active roadmap: [`R-002-duounwan-release`](./roadmaps/active/R-002-duounwan-release.md) — 빌드(완료) → 출시 준비 → 소프트 런칭 → 버스트 1·2

현재 active task: [`BT-009-pivot-release-prep`](./tasks/active/BT-009-pivot-release-prep.md) — 통합 검증, 열린 이슈, 대표 결정, 서버 배포, 심사 제출(수동 출시)

다음 후보 task(미생성): 소프트 런칭 운영(11/3~11/23, Gate 1 11/17) → 버스트 1(11/24~30) → 버스트 2(1/1~7). 일정 정본 `docs/go-to-market/LAUNCH_PLAN_DUOUNWAN.md` §2.

## 현재 제품 방향 (D-007, 2026-10-02)

- 연인·부부가 서로의 운동 약속을 봐주는 1:1 앱 **둘운완 / DuoDone**. 대외 문구 `둘이 보면, 진짜 하게 돼요.`
- 사용자 용어: 짝꿍(애칭 우선) · 운동 약속 · 오운완 인증/인증샷 · 인정 · 똑똑 · 내기 · 둘운완. 코드·데이터의 `partner`·`plan`·`promise`는 유지.
- 정본 스펙: `docs/product/PIVOT_DUOUNWAN_SPEC.md`

## 상태 요약 (2026-10-03)

- 코드: 피벗 빌드 `1.1.0+81` 완료, 브랜치 `feat/couple-workout-pivot` **미커밋**.
- 배포: 없음. 직전 스토어 빌드 `1.0.58+80`.
- 레인별 검증: analyze 0 에러, `flutter test` 557/557(S6 시점), functions 17/17·lint 0, 규칙 21/21, 트리거 13/13. 최종 통합 재실행·iOS/Android 빌드·실기기는 BT-009에서.
- 대표 승인 대기: 서버 배포, 마이그레이션, 스토어 제출, 광고 예산(Gate 0 150만 원), 상표 출원, `LAUNCH_PLAN` §0 결정 1~7.

## 현재 남은 To-do (BT-009 요약)

1. 스펙 §8 게이트 최종 통합 실행 + iOS 시뮬레이터·Android AAB 빌드.
2. 실기기: 인증샷·연결/해제·공유 카드·알림·버전 게이트·DebugView 퍼널 8종.
3. 열린 이슈: 공유 카드 푸터 `Google Play`(2.3.10), 마이그레이션 백업/복원 계약, `release_manual` 레인, 레거시 pending 수정 시 `승인` 푸시, Pretendard 폰트, 노란색 텍스트 대비, 개인정보처리방침 시행일.
4. 대표 결정: 공유 카드 빈도, 영어 용어·키워드, 튜토리얼 키, Temporary Operations Lead 지정.
5. 대표 승인 후 런북 0~6단계(10/27 심사 제출 목표).

## 정리된 이전 작업 (D-007로 종료)

| ID | 이전 상태 | 현재 | 위치 |
|---|---|---|---|
| `G-001-study-sprint-pilot` | Active | `Dropped` | `goals/done/` |
| `R-001-study-sprint-prep` | Active | `Dropped` | `roadmaps/done/` |
| `BT-004-pilot-recruitment-ops` | Active | `Dropped` | `tasks/done/` |
| `BT-005-week-one-pilot-ops-review` | Ready | `Dropped` | `tasks/done/` |
| `BT-006-responsibility-network-thin-slice` | Ready | `Backlog`(보류) | `tasks/backlog/` |

- 4주 스터디 파일럿은 모집 준비 단계에서 멈췄고 파일럿 데이터는 없다.
- 완료된 BT-001·002·003·007·008, NT-001 중 28일 기간·4주 정산·놓친 약속 전달·똑똑 안정화는 둘운완에 남고, 스터디 템플릿·`실천 메이트` 카피는 피벗 빌드에서 교체됐다.

## 읽는 순서

1. `goals/active/`에서 지금 왜 이 일을 하는지 확인한다.
2. `roadmaps/active/`에서 이번 사이클의 순서를 확인한다.
3. `tasks/active/`에서 지금 실제로 끝낼 작업을 확인한다.
4. 완료(`Done`) 또는 중단(`Dropped`)된 항목은 각 `done/` 폴더로 옮기고 상단에 상태와 사유를 남긴다.

## 운영 규칙

- active task는 최대 3개만 둔다.
- task는 반드시 roadmap에, roadmap은 반드시 goal에 연결한다.
- 완료 기준이 없는 task는 active에 두지 않는다.
- 개발 task는 테스트, 빌드/검증, 문서 업데이트 체크를 포함한다.
- `done/` 폴더는 종료 상태(`Done`·`Dropped`)를 함께 보관한다. 방향을 바꾸는 결정은 `docs/decisions/DECISIONS.md`에 먼저 남긴다.
- 배포·스토어 제출·마이그레이션·광고비는 대표 승인 후에만 실행한다.
