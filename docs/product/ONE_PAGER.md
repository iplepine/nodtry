<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (23 files)`
> - 문서 갱신: `2026-10-03 07:18:58 +0900`
<!-- COMMIT_STATUS END -->

# 둘운완 한 장 요약

마지막 갱신: 2026-10-03 · 정본 스펙 [`PIVOT_DUOUNWAN_SPEC.md`](./PIVOT_DUOUNWAN_SPEC.md) · 결정 D-007

## 한 줄 정의
**둘운완**(EN **DuoDone**)은 연인·부부가 서로의 운동 약속을 봐주는 1:1 앱이다.

> 둘이 보면, 진짜 하게 돼요.

이름은 #오운완(오늘 운동 완료)에서 왔다. 둘운완 = 둘 다 오늘 운동 완료.

## 풀려는 문제
- 혼자 정한 운동은 아무도 모르니 쉽게 미룬다. 알림은 무시된다.
- 커플은 이미 서로의 하루를 묻는다. 그 관계를 운동 약속의 확인자로 쓰면 이행이 늘어난다는 것이 핵심 가설이다. `Assumption`
- 비슷한 방식(사진 인증 + 파트너 확인 + 가벼운 벌칙)은 미국 Sweatmates가 평점 약 4.9·평가 약 1.3만으로 보여 줬다. `Evidence`(스토어 관측) 다만 이것은 시장 반응이지 이행률 효과의 증거는 아니다.
- 한국어 커플 운동 인증 앱 자리는 비어 있다. 국내 유사 앱은 평가 30개 미만이다. `Evidence`(2026-10-02 관측)

## 핵심 사용자
- 같이 운동하자고 말은 하지만 혼자서는 미루는 20~30대 연인·부부.
- 서로 "오늘 운동했어?"를 이미 묻는 커플. 한쪽만 운동해도 된다(짝꿍은 봐주는 역할만 해도 됨).
- 제외: 만 14세 미만, 금전 내기를 원하는 사용자(비금전 내기만 지원).

## 목표
- 주 목표: iOS KR 건강 및 피트니스(무료) Top 10에 버스트 중 1회 이상 진입. Play 건강/운동 Top 20~30. `Assumption`(필요 다운로드 하루 1,000~3,000건 추정, 소프트 런칭에서 실측)
- 활성화: 초대→연결 72시간 내 50% 이상, 둘운완 데이→공유 카드 15% 이상. `Assumption`
- 핵심 가설 측정: 연결 사용자와 혼자 쓰는 사용자의 예정일 완료율 비교. 자기선택 편향이 있어 인과로 단정하지 않는다.
- 상세: [`../go-to-market/LAUNCH_PLAN_DUOUNWAN.md`](../go-to-market/LAUNCH_PLAN_DUOUNWAN.md) §1·§7, [`../go-to-market/RETENTION_METRICS.md`](../go-to-market/RETENTION_METRICS.md)

## 핵심 루프
1. **초대** — 내 운동 약속을 걸고 "나 운동 약속 걸었어, 봐줘" 메시지를 공유 시트(카카오톡 등)로 보낸다. 코드 + `https://nod-try.web.app/i/{CODE}` 링크.
2. **연결 + 애칭** — 받는 쪽은 `{초대자}의 운동 약속을 봐줄래요? [내가 봐줄게]` 한 번으로 연결. 이어서 서로 부를 애칭(짝꿍·자기·오빠·여보·애기·직접)을 정한다.
3. **운동 약속 걸기(1화면)** — 운동 타일 14종 → 요일(최소 1개) → 마감 시각(필수) → `🤙 {애칭}이랑 손가락 걸기`. 승인 대기 없이 바로 시작, 28일.
4. **오늘 운동했어?** — 지금 탭 히어로가 오늘 예정·미기록이면 하루 종일 뜬다. `📸 인증샷 찍기` / `사진 없이 했어` / `오늘은 쉴게`.
5. **인정** — 짝꿍은 인증샷과 출처 배지를 보고 ❤️🔥💪👏 한 번 탭으로 인정한다. 한마디는 선택.
6. **안 하면 짝꿍이 안다** — 마감 리마인더 `기록이 없으면 곧 {애칭}한테 알려져요`. 마감 후 30~60분 사이(30분 주기 크론 + 30분 유예)에 미기록이면 짝꿍에게 자동 전달 → `응원 보내기` / `똑똑`. 받은 쪽은 `지금 간다 🏃` / `오늘은 봐줘 🙏`로 답한다.
7. **둘운완** — 두 사람 모두 미스가 없고 적어도 한 명이 한 날. `둘이 함께 N일째` + 이번 주 7일 도트.
8. **공유 카드** — 둘운완 데이, 연속 3·7·30일에 9:16 카드(내 인증샷만)를 인스타·카톡으로 공유.
9. **내기** — `못 지키면 🍗 치킨 쏘기` / `지키면 🍣 같이 오마카세`. 비금전만, 돈 단어는 저장 전 차단.

## 이번 릴리스(1.1.0+81)에서 만든 것

| 영역 | 내용 | 정책 |
|---|---|---|
| 브랜드 | 이름 둘운완/DuoDone, 김홍도 Heart-Check 아이콘, 단일 팔레트(primary `#D92653`), 스플래시·알림 아이콘 | `../design/BRAND.md` |
| 초대·연결 | 공유 시트 초대, 클립보드·링크·직접 입력 코드 감지, 확인 시트, 첫 로그인 초대 단계, 서버 1:1 강제·코드 1회용 | [connect](./policy/connect_policy.md) |
| 애칭 | 연결 직후 애칭 시트, 우리 탭에서 변경, 앱·푸시 전체에 애칭 우선 | [nickname](./policy/nickname_policy.md) |
| 운동 약속 | 1화면 생성, 운동 타일 14종(`workoutType`), 마감 필수, 승인 단계 제거 | [plan](./policy/plan_policy.md) |
| 인증샷 | 동의 시트, 카메라/앨범, EXIF·GPS 제거, Storage 경로만 저장, 짝꿍만 열람, 신고·연결 끊기·삭제 | [proof_photo](./policy/proof_photo_policy.md) |
| 지금 탭 | 오늘 운동했어? 히어로, 원탭 인정, 둘운완 헤더, 초대 카드, 똑똑 답장, 놓친 운동 응원 | [now_tab](./policy/now_tab_policy.md) |
| 둘운완 | 연속 일수·주간 도트(지금·우리·기록 탭), 공유 카드, 평점 요청 | [duo_stats](./policy/duo_stats_policy.md) |
| 내기 | 큐레이션 칩, 못 지키면 먼저, 돈 단어 차단 | [promise](./policy/promise_policy.md) |
| 알림 | 운동 카피, 애칭 라벨, 인증샷 푸시(빌드 81+), 인정 푸시 1건, 시간대 기준 마감, 똑똑 하루 1회 서버 제한 | [notification](./policy/notification_policy.md) |
| 호환·안전 | 최소 버전 게이트(`config/app`), 기존 사용자 1회 공지, 탈퇴 시 서버 정리 | [settings](./policy/settings_policy.md), [auth](./policy/auth_policy.md) |
| 숨김 | 집중 타이머, 단방향 배지, 테마 선택, 어제 인정 rescue 버튼, 가짜 응원 버튼 | [focus_timer](./policy/focus_timer_policy.md) |
| 웹 | 초대 랜딩 `/i/{CODE}`, `/get`, 개인정보처리방침·지원 페이지 갱신 | `../operations/LAUNCH_RUNBOOK.md` 4단계 |

스토어: iOS `둘운완 - 커플 오운완 운동 인증` / Play `둘운완: 커플 오운완 운동 인증`, 캡션 스크린샷 6장, Play 피처 그래픽.

## 의도적으로 안 만든 것
- 금전 내기·결제·보증금 (Pact FTC 환불 사례 `Evidence`)
- 공개 피드·랭킹·그룹, 짝꿍 2명 이상
- 짝꿍 사진이 들어간 공유 카드(동의 이슈)
- 체중감량 효과 주장, 스크린샷·부제의 숫자 효과 주장
- AI 코치, 운동 기록 상세(세트·거리 등)

## 다음 릴리스 후보 (문서화만)
홈/잠금 위젯(1순위), 카카오 FeedTemplate 초대(2순위), Universal/App Link, 같이 했어(한 장으로 둘 다), D-day 목표, 주 N회 자유 요일, 내기 쿠폰·서버 정산, 푸시 일일 상한, users/plans/actions read 축소 보안 묶음(minBuild 상향 후), 푸시 ko/en 분기. 우선순위는 `LAUNCH_PLAN_DUOUNWAN.md` §10.

## 참조
- 범위: [`MVP_SCOPE.md`](./MVP_SCOPE.md) · 유스케이스: [`USE_CASES.md`](./USE_CASES.md) · 브리프: [`PRODUCT_BRIEF.md`](./PRODUCT_BRIEF.md)
- 정책: [`policy/`](./policy/) — auth · connect · nickname · relation · plan · now_tab · proof_photo · duo_stats · history · poke · promise · notification · profile · settings · focus_timer(숨김)
- 데이터: [`../../_spec/15-data-model/firestore-schema.md`](../../_spec/15-data-model/firestore-schema.md) · 이벤트: [`../operations/ANALYTICS_EVENTS.md`](../operations/ANALYTICS_EVENTS.md)
- 출시: [`../operations/RELEASE_READINESS.md`](../operations/RELEASE_READINESS.md) · 작업: [`../work/README.md`](../work/README.md)
