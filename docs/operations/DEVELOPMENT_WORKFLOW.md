# Development Workflow

이 repo의 개발 작업은 project-manager의 공통 워크플로우를 따른다.

공통 원본:

`/Users/basil/Projects/project-manager/PROJECT_WORKFLOW.md`

## 시작 전 확인

- `docs/README.md`
- `docs/product/PRODUCT_BRIEF.md`
- `docs/product/USE_CASES.md`
- `docs/product/MVP_SCOPE.md`
- `docs/product/4_WEEK_PROGRAM_SPEC.md`
- `docs/go-to-market/VERTICAL_SELECTION.md`
- `docs/go-to-market/REVENUE_MODEL.md`
- `docs/go-to-market/RETENTION_METRICS.md`
- `docs/operations/RELEASE_READINESS.md`
- `docs/decisions/DECISIONS.md`

## repo별 주의점

- 일반 습관 앱으로 넓히지 않고 선택한 vertical과 4주 책임 프로그램에 맞춘다.
- 초대, 검증, 알림, 파트너/관리자 역할 변경은 스펙 확인 후 진행한다.
- 정책 상세는 `docs/product/policy/`를 참고한다.
- UI 변경은 iOS 시뮬레이터 수동 확인 스킬을 필요할 때 사용한다.
- 배포 요청은 기본적으로 모바일 내부 테스트 배포 또는 release runbook 기준으로 해석한다.

## 검증 기록

작업 후 최종 보고에 아래를 남긴다.

- 확인한 문서
- 실행한 테스트/빌드 명령
- 수동 확인한 핵심 시나리오
- 갱신한 문서
- 커밋/푸시 여부
