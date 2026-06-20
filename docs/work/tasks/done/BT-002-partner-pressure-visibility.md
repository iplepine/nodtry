<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `d591e92e08aca84dcec3c09187fb4ab615b1419d` (`main`)
> - 최근 커밋: `d591e92e08ac` chore: bump version to 1.0.53+75 (now-tab timing & carousel swipe)
> - 커밋 일시: `2026-06-16T10:09:48+09:00`
> - 워킹트리: `dirty (64 files)`
> - 문서 갱신: `2026-06-20 22:33:15 +0900`
<!-- COMMIT_STATUS END -->

# Task

ID: `BT-002-partner-pressure-visibility`

유형: `Build`

상태: `Done`

연결 Roadmap: `R-001-study-sprint-prep`

연결 Goal: `G-001-study-sprint-pilot`

마지막 갱신일: 2026-05-03

## 목표

첫 주에 파트너 확인, 응원, 똑똑, 놓친 약속 알림이 사용자의 행동을 실제로 당기는 압박으로 보이게 한다.

## 배경

서버에는 놓친 약속 알림(`action_missed`)과 똑똑 이벤트가 있고, Now 탭에는 파트너 카드가 있다. 하지만 파일럿 wedge인 "혼자 못 지키는 약속을 관계로 묶는다"가 화면에서 충분히 선명하지 않다.

## 포함

- Now 탭에서 파트너가 기다리는 상태와 놓친 약속 상태를 더 강하게 구분
- 확인/응원/똑똑 CTA 문구 정리
- `action_missed`, `partnerPoke`, `partnerAction` 노출 정책 점검
- 첫 주 파일럿 질문과 연결되는 수동 검증 시나리오 작성

## 제외

- 다인 그룹 압박
- 공개 랭킹
- 벌점/결제 구현

## 완료 기준

- [x] 첫 주 파트너 압박 상태가 Now 탭에서 묻히지 않음
- [x] missed/poke/confirmation 상태별 CTA가 구분됨
- [x] 관련 테스트 또는 smoke 검증 추가
- [x] `notification_policy.md`, `now_tab_policy.md`, `poke_policy.md` 갱신

## 검증 계획

- `flutter test --reporter expanded`
- 필요 시 iOS/모바일 화면에서 Now 탭 카드 상태 수동 확인
