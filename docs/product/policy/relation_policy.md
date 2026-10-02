<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (41 files)`
> - 문서 갱신: `2026-10-03 07:19:00 +0900`
<!-- COMMIT_STATUS END -->

# 관계(Relation) 정책

마지막 갱신: 2026-10-03 (1.1.0+81)

## 용어
- 사용자에게는 상대를 **애칭 → 표시 이름 → 짝꿍** 순으로 부른다. `실천 메이트`·`메이트`는 쓰지 않는다.
- 코드·데이터의 `partner`, `Manager`, `Executor`, `relations` 이름은 호환성을 위해 유지한다.
- 관계는 연인·부부가 동의한 상호 1:1이다(D-001 상호 지지, D-002 1:1 유지).

## Relation 모델 (`relations/{id}`)
- `managerId`: 이 문서에서 봐주는 쪽 · `executorId`: 약속을 거는 쪽 · `status`: `pending|active|rejected`
- 신규(선택): `inviterId`(코드 소유자 uid), `inviteCode`(입력한 코드). 앱 1.1.0+가 두 문서 모두에 쓴다. 없으면(구버전) 서버가 가입이 오래된 쪽을 초대자로 본다.

## 양방향 생성
- `connectWithCode`가 relation 2개를 한 배치로 만든다: A 초대자=manager·참여자=executor, B 반대.
- 결과: 연결 즉시 상호. 우리 탭에는 양방향 배지만 보인다(단방향 배지 숨김).

## 서버 불변식 (피벗 신규)
- **1:1**: `onRelationCreated`가 둘 중 누구라도 더 오래된 연결이 있으면 새 관계를 지운다.
- **managerId = 연결된 짝꿍**: `onPlanCreated`/`onPlanUpdated`가 relation 없는 `managerId`를 해제한다(위조·오래된 짝꿍의 인증샷 접근 차단).
- **해제 정리**: 두 relation이 모두 사라지면 `onRelationDeleted`가 양쪽 약속의 `managerId` 해제, pending→active, 진행 중 내기 rejected.
- 상세 흐름은 [connect_policy.md](./connect_policy.md).

## 레거시 데이터
- 단방향 relation 1개만 있는 옛 사용자: 앱 로직(똑똑·카드)은 양방향 체크로 호환된다.
- 한 사용자가 짝꿍 2명 이상이거나 relation 없는 `managerId`가 남은 약속: `scripts/migrations/clear_stale_manager_ids.js`가 보고(dry-run 기본)하고 `--apply`로 정리한다(2명 이상은 보고만). 실행은 대표 승인 후, 런북 5단계.

## 다대다
- 책임망(D-005, `RESPONSIBILITY_NETWORK.md`) 확장은 보류다. 둘운완은 커플 1:1만 지원한다. 공개 그룹은 계속 제외.
