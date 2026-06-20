<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `d591e92e08aca84dcec3c09187fb4ab615b1419d` (`main`)
> - 최근 커밋: `d591e92e08ac` chore: bump version to 1.0.53+75 (now-tab timing & carousel swipe)
> - 커밋 일시: `2026-06-16T10:09:48+09:00`
> - 워킹트리: `dirty (64 files)`
> - 문서 갱신: `2026-06-20 22:33:15 +0900`
<!-- COMMIT_STATUS END -->

# Task

ID: `BT-006-responsibility-network-thin-slice`

유형: `Product/Dev`

상태: `Ready`

연결 Roadmap: `R-001-study-sprint-prep`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-05-05

## 목표

Nodtry의 다대다 확장을 공개 그룹이 아니라 `약속별 책임망`으로 구현하기 위한 첫 thin slice를 정의하고 구현한다.

## 배경

현재 앱은 문서와 일부 데이터 모델에서는 여러 관계를 암시하지만, 연결 화면은 추가 파트너 연결을 막고 플랜 생성은 첫 번째 연결 파트너를 자동 담당자로 사용한다. 다음 wedge는 여러 사람이 모두 보는 그룹이 아니라, 약속마다 누가 당겨주는지 명확히 고르는 구조다.

## 범위

포함:

- 여러 파트너 연결 허용 여부와 기존 Firestore relation 구조 점검
- 플랜 생성에서 담당 파트너 선택 UX 정의
- 선택한 담당자를 기존 `managerId`에 저장하는 최소 구현
- 담당자가 없을 때 똑똑/놓친 약속 압박이 약해진다는 경고 유지
- Us 탭에서 사람별 책임 상태가 흐려지지 않는지 확인

제외:

- 공개 그룹 피드
- 공개 랭킹
- 예비 담당자 구현
- 자동 매칭
- 코치/조직 관리자 기능

## 완료 기준

- [ ] 여러 파트너가 연결되어도 기존 1:1 플랜이 깨지지 않음
- [ ] 새 플랜 생성 시 담당 파트너를 명시적으로 선택할 수 있음
- [ ] 선택된 담당자가 플랜의 `managerId`로 저장됨
- [ ] Now/Us 탭에서 내가 당겨야 할 약속과 나를 당기는 사람이 구분됨
- [ ] 책임망 문서와 테스트 시나리오가 갱신됨

## 검증 계획

명령:

- `flutter test --reporter expanded`

수동 확인:

- 파트너 A, 파트너 B를 연결한다.
- 공부 약속은 A에게 맡긴다.
- 운동 약속은 B에게 맡긴다.
- Now 탭에서 각 담당자에게 맞는 카드가 뜨는지 확인한다.
- 담당자가 없는 플랜을 만들 때 경고와 연결 CTA가 유지되는지 확인한다.

## 문서 업데이트 대상

- `docs/product/RESPONSIBILITY_NETWORK.md`
- `docs/product/4_WEEK_PROGRAM_SPEC.md`
- `_spec/20-feature/screens/connect.md`
- `_spec/20-feature/03-03-us-tab.md`

## 사용자 확인

필요 여부: `yes`

확인할 질문:

- 첫 구현은 `여러 파트너 연결 + 플랜별 메인 담당자 선택`까지만 진행한다.

결정:

## 결과

완료 내용:

검증 결과:

남은 리스크:

후속 task:
