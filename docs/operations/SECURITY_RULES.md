<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `d591e92e08aca84dcec3c09187fb4ab615b1419d` (`main`)
> - 최근 커밋: `d591e92e08ac` chore: bump version to 1.0.53+75 (now-tab timing & carousel swipe)
> - 커밋 일시: `2026-06-16T10:09:48+09:00`
> - 워킹트리: `dirty (64 files)`
> - 문서 갱신: `2026-06-20 22:33:15 +0900`
<!-- COMMIT_STATUS END -->

# Firestore / Storage Security Rules

소스 오브 트루스: 레포의 [`firestore.rules`](../../firestore.rules), [`storage.rules`](../../storage.rules),
[`firestore.indexes.json`](../../firestore.indexes.json). `firebase.json`의 `firestore` / `storage`
타깃이 이 파일들을 가리킨다.

## 모델 요약

| 컬렉션 | read | create | update | delete |
|--------|------|--------|--------|--------|
| `users/{uid}` | 로그인 사용자 전체¹ | 본인 | 본인 | 본인 |
| `relations/{id}` | 참가자(executor·manager) | 참가자 | 참가자 | 참가자 |
| `plans/{id}` | 로그인 사용자 전체² | `userId==me` | 참가자 + `userId` 불변 | `userId==me` |
| `actions/{id}` | get: 소유자·plan매니저 / list: 로그인 전체² | `userId==me` | 소유자·plan매니저 | 소유자 |
| `cheers/{id}` | 참가자 | `fromUserId==me` | ✗ | ✗ |
| Storage `users/{uid}/*` | 로그인 사용자 전체 | 본인·이미지<5MB | 본인·이미지<5MB | 본인 |

¹ ² **읽기가 넓은 이유**: 매니저가 파트너의 `users`/`plans`/`actions`를 *파트너 uid로 필터링*해
조회한다(`where userId == partnerId`, `where planId == X`, `whereIn`). Firestore 쿼리 보안 규칙은
정적 분석이라, 문서별 `userId==me` 같은 엄격한 read 규칙을 걸면 이 cross-user 쿼리들이 거부된다.
읽기를 더 좁히려면 모든 문서에 `managerId`를 비정규화하고 cross-user 쿼리를 재작성해야 한다
(P2 데이터 모델 작업 #9와 연결). **이번 강화의 핵심은 write 측 잠금**이다: 비인증 전면 차단,
타인 사칭 불가, 타인 데이터 수정·삭제 불가, plan 소유자 재할당 불가.

## 배포 (프로덕션 영향 — 신중히)

> ⚠️ 보안 규칙은 운영 중인 파일럿 사용자에게 즉시 적용된다. 잘못된 규칙은 앱을 잠근다.
> CI/자동 배포로 묶지 말고 아래 절차를 사람이 직접 확인하며 실행한다.

1. **현재 운영 인덱스를 먼저 백업** (deploy가 파일에 없는 인덱스를 지우자고 물어볼 수 있음):
   ```bash
   firebase firestore:indexes > /tmp/firestore.indexes.live.json
   # 레포의 firestore.indexes.json 과 비교해 누락분을 보강한 뒤 진행
   ```
2. **에뮬레이터로 규칙 컴파일·동작 검증** (Java 필요):
   ```bash
   firebase emulators:exec --only firestore "echo rules-compiled-ok"
   ```
3. **규칙만 먼저 배포** (이번 변경의 핵심):
   ```bash
   firebase deploy --only firestore:rules,storage
   ```
   > 스토리지는 `storage:rules`가 아니라 `storage`로 배포한다. `storage:<이름>`은
   > 멀티버킷용 named target으로 해석돼 "Could not find rules for ... target: rules"
   > 에러가 난다.
4. **인덱스는 별도로**, 1번 비교 후 안전이 확인되면:
   ```bash
   firebase deploy --only firestore:indexes
   ```
5. 배포 직후 실기기에서 스모크: 로그인 → 파트너 연결 → 플랜 생성 → 실천 보고 → 파트너 확인 →
   프로필 이미지 업로드가 모두 동작하는지 확인. 하나라도 막히면 즉시 콘솔에서 이전 규칙으로 롤백.

## 알려진 잔여 리스크 (후속 과제)

- `users` 문서를 로그인 사용자 누구나 읽을 수 있어 `fcmToken`이 노출된다.
  → `fcmToken`을 `users/{uid}/private/tokens` 서브컬렉션(본인만 read)으로 이전.
- `plans`/`actions` list가 넓다. → `managerId` 비정규화 + cross-user 쿼리 재작성(P2 #9).
