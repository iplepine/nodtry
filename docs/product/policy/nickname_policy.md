<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (33 files)`
> - 문서 갱신: `2026-10-03 07:18:59 +0900`
<!-- COMMIT_STATUS END -->

# 애칭(Partner Nickname) 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S5·backend) · 스펙 §3, §4.2

## 개요
연결 직후 서로 부를 애칭을 정한다. 앱 화면과 푸시에서 상대 이름 대신 내가 정한 애칭을 먼저 쓴다. 각자 자기 쪽 애칭만 정한다(내가 짝꿍을 부르는 호칭).

## 데이터
- `users/{me}.partnerNickname` (string, 선택). 앞뒤 공백 제거, **최대 10자(코드포인트)**, 빈 값이면 필드 삭제.
- 짝꿍이 연결돼 있을 때만 적용한다. 남아 있는 애칭은 짝꿍이 없으면 무시한다.

## 라벨 우선순위 (단일 소스)
`애칭 → 짝꿍 표시 이름 → 짝꿍`
- 앱: `partnerLabelProvider` → 위젯은 `ref.watch(partnerLabelProvider).resolve(l10n)`, 뷰모델은 `.preferredFor(uid, displayName:)`.
  - 쓰는 곳: 지금 탭 카드·헤더, 우리 탭 히어로·카드·약속 제목, 기록 항목·필터, 약속 만들기 헤더·CTA·안내, 해제 다이얼로그, 로컬 리마인더 본문.
- 서버 푸시: **수신자**의 `partnerNickname` → 발신자 `displayName` → `짝꿍`(`copy.ts` `partnerLabel`). 짝꿍이 보낸 푸시에 내가 정한 애칭이 보인다.
- 공유 카드: 짝꿍은 애칭 또는 `짝꿍`으로만, **실명은 넣지 않는다**(개인정보).
- 조사: 이름 뒤에는 받침 무관 조사만(`한테`, `의`, `하고`). 받침 의존 조사가 필요하면 `withJosa(nickname, '이랑/랑')`로 미리 붙인 값을 넘긴다(예: `🤙 자기랑 손가락 걸기`, `🤙 오빠랑…`, `🤙 지민이랑…`).

## 애칭 시트 (`partner_nickname_sheet.dart`)
- 프리셋: `짝꿍`(기본) · `자기` · `오빠` · `여보` · `애기` · `직접 입력`. 이미 있으면 `애칭 지우기`.
- 영어 프리셋: Partner / Babe / Honey / Love / Baby (S5 레인 번역, 마케팅 확인 대기).
- 여는 곳:
  - 연결 직후(성공 화면 다음). 30분 안에 라이브로 연결됐으면 `연결됐어요` 축하 문구.
  - 홈 프롬프트로 **짝꿍당 1회**(`nickname.prompted_partner_v1`). 이미 연결된 기존 커플도 업데이트 후 한 번 본다.
  - 우리 탭 짝꿍 카드 탭 또는 `애칭 정하기/바꾸기` 필.
- 분석: `partner_nickname_set {kind: preset|custom|removed}` — 애칭 텍스트는 보내지 않는다.

## 삭제
- 내가 연결을 끊으면 앱이 내 `partnerNickname`을 지운다.
- 짝꿍이 끊으면 앱 루트의 `partnerLinkBinderProvider`가 내 애칭을 지운다.
- 서버 `onRelationDeleted`도 짝꿍이 없어진 사람의 `partnerNickname`을 지운다. 새 짝꿍이 전 짝꿍의 애칭으로 불리지 않게 하기 위해서다(스펙에 없던 레인 결정).

## 알려진 한계
- 현재 users read 규칙상 로그인 사용자 누구나 `partnerNickname`을 읽을 수 있다(`displayName`과 같은 노출 수준). read 축소 보안 묶음에서 함께 다룬다.
- 리마인더 본문의 애칭은 예약 시점 값이다. 바꾼 애칭은 다음 재예약 때 반영된다.
