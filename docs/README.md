<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (4 files)`
> - 문서 갱신: `2026-10-03 07:18:55 +0900`
<!-- COMMIT_STATUS END -->

# 둘운완 (DuoDone) 문서

**둘운완**은 연인·부부가 서로의 운동 약속을 봐주는 1:1 앱이다. 혼자선 미루는 운동, 둘이 보면 진짜 하게 된다.

> 대외 문구: `둘이 보면, 진짜 하게 돼요.`

- 2026-10-02 D-007로 `Nodtry / 그래,해봐 / 실천 메이트`에서 피벗했다. 번들 ID(`com.devho.nodtry.app`), Firebase 프로젝트(`nod-try`), 데이터 필드명(`partner`, `manager`, `plan` 등)은 그대로다.
- 현재 상태(2026-10-03): 피벗 빌드 `1.1.0+81` 코드 완료, **커밋·배포 전**. 서버 배포·스토어 제출·마이그레이션·광고 예산은 대표 승인 대기.

## 지금 읽는 순서

1. [product/PIVOT_DUOUNWAN_SPEC.md](./product/PIVOT_DUOUNWAN_SPEC.md) — 피벗 단일 정본 스펙
2. [decisions/DECISIONS.md](./decisions/DECISIONS.md) D-007 — 왜 피벗했나, 무엇을 대체했나
3. [product/ONE_PAGER.md](./product/ONE_PAGER.md) — 한 장 요약: 핵심 루프, 이번에 만든 것, 안 만든 것
4. [work/README.md](./work/README.md) — 현재 goal·roadmap·task (`G-002` / `R-002` / `BT-009`)
5. [operations/RELEASE_READINESS.md](./operations/RELEASE_READINESS.md) → [operations/LAUNCH_RUNBOOK.md](./operations/LAUNCH_RUNBOOK.md) — 출시 게이트와 배포 순서
6. [go-to-market/LAUNCH_PLAN_DUOUNWAN.md](./go-to-market/LAUNCH_PLAN_DUOUNWAN.md), [ASO_DUOUNWAN.md](./go-to-market/ASO_DUOUNWAN.md) — 출시·버스트 계획, 스토어 메타데이터
7. [product/policy/](./product/policy/) — 기능별 상세 정책

## 역할별 바로가기

| 역할 | 문서 |
|---|---|
| 개발 | `product/policy/`, `../_spec/15-data-model/firestore-schema.md`, `operations/SECURITY_RULES.md`, `operations/ANALYTICS_EVENTS.md` |
| 출시 | `operations/RELEASE_READINESS.md`, `operations/LAUNCH_RUNBOOK.md`, `operations/STORE_CONSOLE_CHECKLIST.md` |
| 마케팅·성장 | `go-to-market/LAUNCH_PLAN_DUOUNWAN.md`, `ASO_DUOUNWAN.md`, `RESEARCH_LOG.md`, `RETENTION_METRICS.md`, `VERTICAL_SELECTION.md` |
| 디자인 | `design/BRAND.md`, `design/brand-system.png`, `design/icon-drafts/` |

## 문서 구조

- `product/`: 제품 정의(원페이저·브리프·MVP 범위·유스케이스), 피벗 스펙
- `product/policy/`: 기능별 동작 정책 원문
- `go-to-market/`: 카테고리 선택, 지표, 출시·ASO 계획, 리서치 로그
- `operations/`: 출시 준비, 런북, 보안 규칙, 분석 이벤트, 크래시 리포팅
- `design/`: 브랜드 가이드와 아이콘 시안
- `decisions/`: 제품·사업 의사결정 기록
- `work/`: goal, roadmap, task
- `archive/`: 정본이 아닌 과거 문서 보관

## 정본 원칙

- 피벗 관련 충돌이 있으면 `PIVOT_DUOUNWAN_SPEC.md`가 우선한다. 상세 동작은 `product/policy/`를 따른다.
- 방향을 바꾸는 결정은 `decisions/DECISIONS.md`에 먼저 남긴다.
- 사업 주장에는 근거 라벨을 붙인다: `Assumption` → `Signal` → `Evidence`. 정의는 `go-to-market/RESEARCH_LOG.md` 2026-10-02 절.
- 사용자 용어는 짝꿍·운동 약속·오운완 인증·인정·똑똑·내기·둘운완이다. 코드·데이터의 `partner`·`plan`·`promise` 이름은 바꾸지 않는다.

## 피벗 이전 문서 (정본 아님, 이력 보존)

아래 문서는 `실천 메이트`·`4주 스터디 파일럿` 시기의 기록이다. D-007로 대체됐고, 근거 추적용으로만 남긴다.

- `product/4_WEEK_PROGRAM_SPEC.md`, `product/RESPONSIBILITY_NETWORK.md`
- `go-to-market/STUDY_SPRINT_PILOT_PLAN.md`, `go-to-market/SUCCESS_STORIES.md`, `go-to-market/REVENUE_MODEL.md`
- `work/REMAINING_IMPROVEMENTS.md` (P0~P2 스윕 잔여 항목. 일부는 피벗 빌드에서 해결)
- `../_spec/20-feature/`, `../_spec/99-test/` (3단계 위자드·스터디 템플릿 기준 화면 스펙)
