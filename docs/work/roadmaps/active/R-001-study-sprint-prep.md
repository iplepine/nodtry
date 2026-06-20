<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `d591e92e08aca84dcec3c09187fb4ab615b1419d` (`main`)
> - 최근 커밋: `d591e92e08ac` chore: bump version to 1.0.53+75 (now-tab timing & carousel swipe)
> - 커밋 일시: `2026-06-16T10:09:48+09:00`
> - 워킹트리: `dirty (64 files)`
> - 문서 갱신: `2026-06-20 22:33:15 +0900`
<!-- COMMIT_STATUS END -->

# Roadmap

ID: `R-001-study-sprint-prep`

상태: `Active`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-06-20

## 목적

4주 스터디 책임 스프린트를 10쌍 파일럿으로 운영할 수 있도록 제품 흐름, 지표, 문서를 준비한다. 이후 확장은 공개 그룹이 아니라 약속별 책임망으로 둔다.

## 기간

시작: 2026-05-03

목표 종료: 2026-06-27

## 진행률

진행률: 95%

근거: thin slice 대조, 스터디 템플릿/기본값, 파트너 압박 가시성, 4주 정산 카드, 똑똑/놓친 약속 푸시 안정화, Cloud Functions 배포, 최근 외부 배포(`1.0.52+74`)까지 완료됐다. 현재 코드 HEAD는 `1.0.53+75`이며, 파일럿 시작 전 모집 운영 준비, 수동 집계 위치 확정, 파일럿 배포 대상 버전 판단이 남아 있다.

## Milestones

| 순서 | Milestone | 완료 기준 | 상태 |
|---:|---|---|---|
| 1 | 파일럿 문서 고정 | 실행 계획, 지표, 가격 의향 질문 완료 | `Done` |
| 2 | 제품 thin slice 대조 | 빠진 흐름이 task로 분리됨 | `Done` |
| 3 | 파일럿 필수 구현 보완 | 파트너 압박 가시성과 4주 정산 준비 | `Done` |
| 4 | 배포/알림 안정화 | 똑똑, 놓친 약속 푸시, production 배포 확인 | `Done` |
| 5 | 파일럿 모집 준비 | 안내 문구와 시작 전 질문 확정 | `Active` |

## Active Tasks

- `BT-004-pilot-recruitment-ops`

## Backlog Tasks

- `BT-005-week-one-pilot-ops-review`
- `BT-006-responsibility-network-thin-slice`
- 1주차 수동 집계 시트 작성

## Done Tasks

- `NT-001-study-sprint-thin-slice`
- `BT-001-study-template-defaults`
- `BT-002-partner-pressure-visibility`
- `BT-003-four-week-settlement`
- `BT-007-notification-production-hardening`

## 제외

이번 roadmap에서 하지 않는 일:

- 결제 구현
- 공개 다인 그룹/랭킹
- 공부 타이머

## 검증 계획

테스트: 파트너 연결, 플랜 생성, 확인/응원, 똑똑 카드 제거, 정산 관련 테스트

빌드/QA: Android internal/production, iOS TestFlight/App Store review, Cloud Functions 배포 검증, `1.0.53+75` 파일럿 적용 여부 판단

사용자/시장 검증: 성인 학습자 10쌍 파일럿

## 완료 후 업데이트

- [ ] 연결 Goal 지표 갱신
- [x] 제품 문서 갱신
- [x] 진행상황 문서 갱신
- [x] 완료 task 이동
