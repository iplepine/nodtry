<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (3 files)`
> - 문서 갱신: `2026-10-03 07:18:55 +0900`
<!-- COMMIT_STATUS END -->

# 스펙 문서

> **2026-10-03 둘운완 피벗(D-007) 안내** — 현재 제품 정본은 `docs/product/PIVOT_DUOUNWAN_SPEC.md`와 `docs/product/policy/`다.
> 이 폴더에서 피벗에 맞춰 갱신된 문서는 [`15-data-model/firestore-schema.md`](./15-data-model/firestore-schema.md)뿐이다.
> `00-meta/`, `10-domain/`, `20-feature/`, `50-ui/`, `60-ux/`, `90-biz/`, `99-test/`는 `Nodtry / 실천 메이트`·3단계 위자드·스터디 템플릿 시기의 기록이다. 충돌하면 `docs/` 쪽을 따른다.

이 폴더는 프로젝트의 스펙 문서를 다음 구조에 맞추어 관리합니다.

## 폴더 구조

*   **00-meta:** 프로젝트 전반의 규칙, 목표, 원칙, 용어 정의 등 메타 정보.
*   **10-domain:** 핵심 도메인 지식 및 비즈니스 로직 (심리학, 뇌과학 이론 등).
*   **15-data-model:** 데이터 구조, 스키마, 엔티티 정의.
*   **20-feature:** 각 기능별 상세 요구사항 및 플로우.
*   **40-api:** 외부 인터페이스 및 API 명세.
*   **50-ui:** 디자인 시스템, 화면별 UI 스펙.
*   **60-ux:** UX 라이팅, 보이스 톤, 사용자 경험 가이드라인.
*   **90-biz:** 수익화 전략 및 사업성 검토 문서.

## 주요 문서 링크

- [MVP 스펙](./00-meta/mvp-spec.md)
- [역할 모드 스펙](./10-domain/role-mode-spec.md)
- [디자인 스펙](./50-ui/design-spec.md)
- [아키텍쳐 스펙](./00-meta/architecture.md)
- [페르소나 정의](./60-ux/personas.md)
- [TODO 리스트](./00-meta/workflow/TODO.md)
- [우선순위 백로그](./00-meta/workflow/priority-backlog.md)
- [iOS 릴리즈 런북](./00-meta/workflow/ios-release-runbook.md)
