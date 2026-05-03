# 공통 개발 워크플로우

모든 AI/Codex 개발 작업은 중앙 워크플로우를 따른다.

- 원본: `/Users/basil/Projects/project-manager/PROJECT_WORKFLOW.md`
- 이 repo의 예외/실행 명령: [docs/operations/DEVELOPMENT_WORKFLOW.md](docs/operations/DEVELOPMENT_WORKFLOW.md)

기본 순서:

1. `docs/README.md`를 먼저 확인한다.
2. 관련 제품/시장/운영/결정 문서를 확인한다.
3. 기능, UX, 데이터, 알림/권한, 제품 범위가 바뀌면 스펙을 정리하고 사용자 확인을 받는다.
4. 승인된 범위만 thin slice 단위로 구현한다.
5. 각 slice마다 즉시 검증하고 테스트를 추가/수정한다.
6. 통합 테스트, 정적 분석, 빌드 또는 smoke 검증을 실행한다.
7. 관련 문서를 갱신한다.
8. 사용자 요청과 현재 세션의 상위 지시에 따라 커밋하고, 원격이 있으면 푸시한다.

`배포해줘` 요청은 중앙 워크플로우의 배포 명령 처리 규칙을 따른다.
