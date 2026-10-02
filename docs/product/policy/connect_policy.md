<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 짝꿍 초대·연결(Connect) 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S5·backend)

## 원칙
- 연인·부부 1:1. 사용자당 짝꿍 1명. **서버가 강제한다**(`onRelationCreated`).
- 연결은 서로의 운동 약속을 봐주고 인정해 주기 위한 동의다. 감시 권한이 아니다.
- 연결하면 운동 약속·인증샷·기록이 짝꿍 1명에게만 보인다. 언제든 끊을 수 있다.

## 초대 코드
- 8자리 `[A-Z0-9]`. 새 코드는 헷갈리는 글자를 뺀 `ABCDEFGHJKMNPQRSTUVWXYZ23456789` + `Random.secure`(앱·서버 동일). 0/O/1/I/L이 든 옛 코드도 계속 유효.
- 생성·백필 시 중복 검사(최대 3회).
- **1회용**: 서버가 연결 때 두 사람 모두, 해제 때 짝꿍이 없어진 사람의 코드를 새로 발급한다. 앱은 `users.inviteCode`를 캐시하지 말고 실시간으로 읽는다.
- 입력 정규화: 앞뒤 공백 제거, 대문자, 공백·하이픈 제거.
- 텍스트에서 찾기(`findInviteCodeInText`): `/i/` 링크 안 코드 우선 → 독립된 8자리 대문자 토큰. 숫자만 있는 토큰(날짜 등)은 건너뛴다.

## 초대 보내기 (초대자)
- 연결 화면 기본은 초대자 모드: 내 코드 크게(`ABCD 2345`), `카톡으로 초대 보내기`(시스템 공유 시트, iPad 앵커), `코드 복사`, 아래 `받은 코드가 있나요?` 입력.
- 메시지(ko): `나 운동 약속 걸었어 🤙 {이름} 운동하는지 봐줘! 둘운완 깔고 코드 {CODE} 넣으면 연결돼 → https://nod-try.web.app/i/{CODE}`. 진행 중 약속이 없으면 `걸 거야`로 바꿔 사실과 다르게 말하지 않는다.
- 노출 위치: 연결 화면, 첫 로그인 초대 단계, 지금 탭 초대 카드, 우리 탭.
- 분석: `invite_shared {channel, surface, has_promise}`, 레거시 `invite_code_shared {method}` 유지.

## 코드 받기 (초대받는 사람)
모든 경로(직접 입력·클립보드·링크)가 같은 순서를 탄다.
1. 이미 짝꿍이 있으면 막는다.
2. `getUserByInviteCode`로 소유자 조회. 없는 코드·내 코드는 조용히 무시(클립보드) 또는 오류(직접 입력).
3. 확인 시트: 상대 아바타 + `{이름}의 운동 약속을 봐줄래요?` + `[내가 봐줄게]`
4. 연결 → 성공 화면 → 애칭 시트 → `나도 걸래? [나도 걸기][나중에]`
- 클립보드는 `Clipboard.hasStrings()` 뒤에만 읽는다(iOS 16+ 붙여넣기 허용 팝업 최소화). 첫 로그인 뒤 1회, 연결 화면 진입 시.
- 링크: Hosting `/i/{CODE}` 랜딩이 코드를 클립보드에 복사하고 스토어로 보낸다(데스크톱은 두 스토어 링크 표시). Play 링크에 `referrer=invite_code%3D{CODE}`를 붙이지만 **앱은 아직 Install Referrer를 읽지 않는다** — 설치 후 클립보드 확인이 코드를 잡는다. 앱 라우트 `/i/:code`(`onmybehalf://app/i/CODE`)는 로그인 전이면 코드를 보관하고 튜토리얼을 건너뛴다. Universal/App Link는 다음 릴리스.
- 분석: `invite_code_detected {source: clipboard|manual|link, matched}`, `connect_code_submitted {source}`, `connect_failed {reason: not_found|self_code|owner_taken|self_taken|exception}`

## 연결 처리
- 앱: relation 2개를 한 배치로 만든다(A: 초대자=manager·참여자=executor, B: 반대). 두 문서 모두 `inviterId`(코드 소유자 uid)·`inviteCode`(입력한 코드)를 기록.
- 서버 `onRelationCreated`(쌍당 1회):
  - 자기 자신 연결 삭제.
  - 둘 중 한 명이라도 더 오래된 연결이 있으면 새 관계 삭제 + 코드 입력자에게 `partner_connect_failed {reason: owner_taken|self_taken}`.
  - `inviteCode`가 초대자의 현재 코드와 다르면 연결 취소(`invalid_code`).
  - 성공 시 두 사람 코드 회전, 양쪽의 managerId 없는 active 약속에 짝꿍 지정(`lastUpdatedBy: 'system_link'`, 상태 유지), 초대자에게 `partner_connected` 푸시 1건(`모르는 사람이라면 앱에서 연결을 끊어 주세요` 안내 포함).
  - 초대자 판정: `inviterId`가 있으면 그것, 없으면(구버전) 가입이 더 오래된 쪽.
- 앱도 연결 직후 best-effort로 기존 active 약속에 `managerId`만 지정한다(pending으로 되돌리지 않음).
- 분석: `partner_connected {role: inviter|invitee}` — 앱 루트의 `partnerLinkBinderProvider`가 라이브 연결 순간 1회 기록. 앱이 꺼져 있던 초대자는 기록되지 않는다(푸시는 감).

## 첫 실행 온보딩
- 새 사용자이고 짝꿍이 없으면 로그인 직후 `/onboarding/invite`: `초대 코드 받았어요` / `나중에 초대할게요`. 기존 사용자는 이 단계를 보지 않는다.
- 튜토리얼 첫 실행에만 `초대 코드 받았어요` 링크(남은 페이지 건너뛰고 로그인 뒤 코드 입력).

## 연결 해제
- 우리 탭 또는 인증샷 보기에서 확인 다이얼로그 → `disconnectByUser`. 내 `partnerNickname`도 지운다.
- 서버 `onRelationDeleted`(쌍당 멱등, 두 relation이 모두 지워진 뒤 1회):
  - 양쪽 plans의 `managerId` 해제, `pending_approval` → `active`, 진행 중 내기 → `rejected`, `lastUpdatedBy: 'system_unlink'`(푸시 없음).
  - 짝꿍이 없어진 사람은 새 초대 코드 + `partnerNickname` 삭제.
- 앱: 양쪽 기기의 인증샷 캐시 삭제. Storage 규칙이 현재 `managerId` 기준이라 전 짝꿍은 즉시 사진을 읽을 수 없다.

## 알려진 한계
- 빌드 81은 `resolveInviteCode`/`redeemInviteCode` callable로 조회·연결한다(함수 미배포 시에만 기존 users 쿼리로 대체). 배포 규칙은 현재 초대 코드가 찍힌 relation만 허용하고, 구버전(코드 미기록) 연결은 `config/app.legacyLinkUntil` 기간에만 허용한다. 남은 위험(users 나열로 코드 수집)은 `firestore.rules.next` 전환으로 닫는다(`docs/operations/SECURITY_RULES.md`). 새 짝꿍은 연결 이전 인증샷을 볼 수 없다(look-back 0).
- 같은 쌍의 연결·해제가 2분 안에 반복되면 서버 이벤트 잠금으로 두 번째 처리가 건너뛰어진다(managerId 가드는 유지).
- callable 경로에서는 거부 사유(`owner_taken`/`self_taken`)를 바로 구체 오류로 보여 준다. 구버전 직접 쓰기 경로에서 서버가 연결을 취소하면 사유는 `partner_connect_failed` 푸시로 전달된다.
