<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# Roadmap

ID: `R-001-study-sprint-prep`

상태: `Active`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-06-20

## 목적

4주 스터디 실천 메이트 스프린트를 10쌍 파일럿으로 운영할 수 있도록 제품 흐름, 지표, 문서를 준비한다. 핵심은 작은 약속을 알아봐 주는 한 사람의 피드백이 다음 실천율을 높이는지 검증하는 것이다. 이 효과는 아직 `Assumption`이며, 여러 사람이나 관계 유형별 확장은 1:1 근거가 생긴 뒤 판단한다.

## 기간

시작: 2026-05-03

목표 종료: 2026-06-27

## 진행률

진행률: 95%

근거: thin slice 대조, 스터디 템플릿/기본값, 실천 메이트 피드백 가시성, 4주 정산 카드, 똑똑/놓친 약속 푸시 안정화, Cloud Functions 배포, 최근 외부 배포(`1.0.52+74`)까지 완료됐다. 현재 코드 HEAD는 `1.0.53+75`이며, 파일럿 시작 전 모집 운영 준비, 핵심 가설 수동 집계 위치 확정, 파일럿 배포 대상 버전 판단이 남아 있다.

## Milestones

| 순서 | Milestone | 완료 기준 | 상태 |
|---:|---|---|---|
| 1 | 파일럿 문서 고정 | 실행 계획, 지표, 가격 의향 질문 완료 | `Done` |
| 2 | 제품 thin slice 대조 | 빠진 흐름이 task로 분리됨 | `Done` |
| 3 | 파일럿 필수 구현 보완 | 실천 메이트 피드백 가시성과 4주 정산 준비 | `Done` |
| 4 | 배포/알림 안정화 | 똑똑, 놓친 약속 푸시, production 배포 확인 | `Done` |
| 5 | 1인 포지셔닝·측정 정렬 | 실천 메이트 문구와 핵심 가설 측정 기준이 운영 문서에 반영됨 | `Done` |
| 6 | 파일럿 모집 준비 | 안내 문구와 시작 전 질문 확정 | `Active` |

## Active Tasks

- `BT-004-pilot-recruitment-ops`

## Backlog Tasks

- `BT-005-week-one-pilot-ops-review`
- `BT-006-responsibility-network-thin-slice` (1:1 효과 근거 전에는 착수 보류)
- 1주차 수동 집계 시트 작성

## Done Tasks

- `NT-001-study-sprint-thin-slice`
- `BT-001-study-template-defaults`
- `BT-002-partner-pressure-visibility`
- `BT-003-four-week-settlement`
- `BT-007-notification-production-hardening`
- `BT-008-one-person-positioning`

## 제외

이번 roadmap에서 하지 않는 일:

- 결제 구현
- 공개 다인 그룹/랭킹
- 공부 타이머

## 검증 계획

테스트: 실천 메이트 연결, 플랜 생성, 확인/응원, 똑똑 카드 제거, 정산 관련 테스트. 코드·데이터의 기존 `partner_*` 명칭은 유지한다.

빌드/QA: Android internal/production, iOS TestFlight/App Store review, Cloud Functions 배포 검증, `1.0.53+75` 파일럿 적용 여부 판단

사용자/시장 검증: 성인 학습자 10쌍 파일럿에서 초대/연결 완료, 피드백 발송률·지연, 피드백 후와 없음의 다음 실천율, 응원/감시/부담 인식, 같은 실천 메이트와 지속 의향을 수집한다. 관계 유형은 선택 예시로만 기록하고 세그먼트 성과로 해석하지 않는다.

## 완료 후 업데이트

- [ ] 연결 Goal 지표 갱신
- [x] 제품 문서 갱신
- [x] 진행상황 문서 갱신
- [x] 완료 task 이동
