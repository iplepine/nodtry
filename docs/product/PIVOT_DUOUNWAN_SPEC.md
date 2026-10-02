# 둘운완 피벗 스펙 (v2, 2026-10-02)

> 대표 지시(2026-10-02): "커플이 봐주면 내가 하기로 한 운동을 실제로 더 한다. 진짜 핵심 기능만 최대한 강조해서 스토어 카테고리 Top 10에 들 수 있게 개선. 앱 이름·이미지 변경 포함 전권 위임."
> 이 문서가 피벗 작업의 단일 정본 스펙이다. 결정 기록은 `docs/decisions/DECISIONS.md` D-007. v1 대비 변경: 마케팅·커플 사용자·제품/리스크 3인 비평 반영(애칭, 둘운완 정의, 공유 카드, 안전 패키지, 서버 1:1 강제, 최소 버전 게이트, 카피 톤 규칙).

## 1. 한 줄 정의
**둘운완**은 연인·부부가 서로의 운동 약속을 봐주는 앱이다. 혼자선 미루는 운동, 둘이 보면 진짜 하게 된다.

- 대외 핵심 문구(ko): `둘이 보면, 진짜 하게 돼요.` — `애인`은 기혼자에게 오해 소지가 있어 대외 문구에 쓰지 않는다(스토어 키워드 필드에만).
- 이름: KO **둘운완**(#오운완 → 둘 다 오늘 운동 완료), EN **DuoDone**. 번들 ID·Firebase·데이터 필드명은 유지.
- 아이콘: 디자인팀 4안 중 **김홍도 Heart-Check** 선정 — 노란 반쪽(짝꿍의 인정)과 흰 반쪽(나의 오운완)이 합쳐 하나의 체크가 된다. 원본: scratchpad `design/kim-hongdo/`. 시스템화(모노크롬·알림 아이콘·스플래시)는 신사임당 안의 방식을 따른다.
- 브랜드 팔레트(라이트): primary `#D92653`, primaryPressed `#B81C45`, primarySoft `#FFE8ED`, secondary(인정 옐로) `#FFD84D`, background `#FFF8F6`, surface `#FFFFFF`, textPrimary `#2B1B21`, textSecondary `#6F5C63`, 아이콘 배경 그라데이션 `#FF6B5E → #FF3577`(단색 대체 `#FF506A`). 테마 선택 기능은 숨기고 단일 팔레트로 고정.

## 2. 근거 요약 (상세: `docs/go-to-market/RESEARCH_LOG.md`)
- 목표 카테고리: **iOS KR 건강 및 피트니스(무료)** 주, 라이프스타일 보조. Google Play는 생산성 → 건강/운동 이동, 1차 목표 Top 20~30.
- 화이트스페이스: 한국어 커플 전용 "운동 약속 + 인증샷 + 짝꿍 인정 + 데이트 내기" 앱 부재. 미국 Sweatmates가 같은 방식 검증(한국어 미지원). 국내 유사 앱(투투·키피럽·다메다메)은 평가 30개 미만.
- Top 10은 최근 3~7일 다운로드 속도 싸움(추정 iOS 하루 1,000~3,000, 미검증). 초대 루프는 배수(K≤1)일 뿐이라 **공유 카드 + 출시 버스트(In-App Event·광고)**가 필요 — 예산은 대표 승인 사항.
- 외부 근거 수치(Wallace 1995 6.3% vs 43%, stickK 29%→59%)는 긴 설명에서만 출처와 함께 "연구 소개"로. 스크린샷·부제·짧은 설명에는 숫자 주장 금지. 체중감량 효과 주장 금지.

## 3. 용어와 톤
| 개념 | 사용자 용어 | 코드/데이터 (변경 금지) |
|---|---|---|
| 상대 | **애칭**(내가 정한 호칭) → 없으면 상대 표시 이름 → 없으면 **짝꿍** | `partner`, `manager` |
| 약속 | **운동 약속** (레거시 비운동 약속은 그냥 **약속**) | `plan` |
| 했어 기록 | **오운완 인증** / 사진이 있으면 **인증샷** | `completedDates`, action `done` |
| 상대 확인 | **인정** (원탭 리액션 ❤️🔥💪👏) | `verifiedDates`, `verifiedBy` |
| 재촉 | **똑똑** | `poke` |
| 보상/벌칙 | **내기** — 지키면 / 못 지키면, 비금전만 | `promise` |
| 둘 다 해낸 날 | **둘운완** | 클라이언트 파생 지표 |
| 3번째 탭 | **우리** | `UsScreen` |

- 제거: `실천 메이트`, `실천`(동사로서의 일반 사용은 문맥상 허용 최소화), `공부`, `스터디`, `4주 스프린트/파일럿`, `Nod&Try`, `Nodtry`, `그래,해봐`.
- 톤 규칙: 앱이 하는 말(안내·시스템 문구)은 **해요체**. 짝꿍끼리 오가는 말(주요 버튼, 똑똑 프리셋, 답장, 한마디 예시)은 **반말**. 예: 시스템 `오늘 둘운완이에요 🎉` / 버튼 `사진 없이 했어`, `오늘은 쉴게`, `내가 봐줄게`.
- `{name}님` 표기 금지(회사 메신저 느낌). 변수 뒤에는 받침 무관 조사만: `{name}한테`, `{name}의`, `{name} 오늘 …`. 이/가·을/를이 꼭 필요하면 조사 헬퍼 사용.
- 감시 뉘앙스 금지: "감시/검사/체크당함" 대신 "봐준다/인정해준다". 불인정·반려 버튼 없음.
- 내기는 비금전(치킨·커피·설거지·마사지·영화 고르기 등). 입력에 `원|만원|₩|현금|송금|계좌|포인트`가 있으면 저장 전 안내.

## 4. 핵심 루프 (이것만 강조)
1. **초대** — 초대자가 먼저 자기 운동 약속을 걸고 "나 운동 약속 걸었어, 봐줘" 톤의 메시지를 공유 시트(카카오톡 포함)로 보낸다. 메시지에 코드와 링크(`https://nod-try.web.app/i/{CODE}`) 모두 포함. 로그인 직후 짝꿍이 없으면 초대 단계(나중에 가능). 받는 쪽은 코드 감지 시 튜토리얼을 건너뛰고 `{초대자}의 운동 약속을 봐줄래요? [내가 봐줄게]` 1탭 연결 → `나도 걸래? [나도 걸기][나중에]`.
2. **애칭** — 연결 직후 서로 부를 애칭을 정한다(자기/오빠/여보/애기/직접, 기본 짝꿍). 앱 화면·푸시에서 애칭 우선.
3. **운동 약속 걸기(1화면)** — 운동 타일(헬스/러닝/홈트/걷기/필라테스/요가/스트레칭/수영/클라이밍/자전거/등산/근력/식단·야식 참기/직접) → 요일(최소 1개) → 마감 시각(필수) → `🤙 {애칭}랑 손가락 걸기`. 짝꿍이 있어도 바로 active(승인 대기 없음). 화면에 `못 하면 {애칭}한테 알려져요` 명시.
4. **오늘 운동했어?** — 지금 탭 히어로(오늘 예정 && 미기록이면 하루 종일 노출). `📸 인증샷 찍기` / `사진 없이 했어` / `오늘은 쉴게`(휴식권). 레거시 비운동 약속은 `오늘 '{title}' 했어?` + `인증하기`.
5. **인정** — 짝꿍 화면에 인증샷(출처 배지: `📸 방금 찍음 · 19:42` / `🖼️ 앨범 · 9/28 촬영`) + 원탭 리액션 = 인정. 한마디는 선택. 인정 푸시 1건만.
6. **안 하면 짝꿍이 안다** — 짝꿍 있는 약속의 마감 리마인더 본문 `기록이 없으면 곧 {애칭}한테 알려져요`(정확한 분 단위 약속 금지, 크론 주기상 +30~60분). 마감 후 미기록이면 짝꿍에게 자동 전달 → `응원 보내기`(주) / `똑똑`(보조). 똑똑은 서버에서 약속당 하루 1회 제한, 받는 쪽 원탭 답장 `지금 간다 🏃` / `오늘은 봐줘 🙏`.
7. **둘운완** — 각자: 예정일이면 done(또는 휴식권/인정받은 rescue), 비예정일이면 중립. 두 사람 모두 미스 없음 && 적어도 한 명이 done인 날 = 둘운완 데이. 인정은 조건이 아니라 ❤️ 보너스 표시. 오늘은 진행 중이면 끊지 않음. 지금 탭 헤더와 우리 탭에 `둘이 함께 N일째` + 이번 주 나/짝꿍 7일 도트.
8. **공유 카드** — 첫 둘운완 데이와 연속 3/7/14/21/30/50/100일에 한 번씩 자동 제안(우리 탭의 수동 버튼은 항상). 9:16 카드(내 인증샷 + `#둘운완 연속 N일` + 둘의 운동 + 날짜 + 플랫폼 중립 문구 `스토어에서 '둘운완' 검색` — Apple 2.3.10). 짝꿍 사진은 v1에서 넣지 않음(동의 이슈). share_plus로 인스타/카카오 공유.
9. **내기** — 약속에 `못 지키면 🍗 치킨 쏘기` / `지키면 🍣 같이 오마카세` 카피·큐레이션 카드. 정산 로직은 유지.
10. **평점 요청** — 첫 둘운완 데이 또는 3번째 인정을 받은 직후 in_app_review(OS 제한 내, 기능 차단 없음).

## 5. 안전·호환 패키지 (출시 필수)
- 인증샷 저장: Storage `proofs/{ownerUid}/{planId}/{actionId}.jpg`, Firestore에는 **경로만**(`actions.proofPhotoPath`, `plans.lastProofPhotoPath`, `proofSource`, `proofTakenAt`). 다운로드 URL 저장 금지. 렌더는 `ref.getData()` + 경로 키 로컬 캐시(연결 해제 시 캐시 삭제).
- 업로드 전 1440px 축소 + JPEG 재인코딩으로 **EXIF/GPS 전부 제거**. 8초 타임아웃, 실패 시 사진 없이 완료 + 안내.
- Storage 규칙: read = owner || (`plans/{planId}.managerId == auth.uid` && 사진이 짝꿍 연결 시점(`managerSince`) 이후); create = owner && jpeg && <3MB && plan.userId==owner; update 금지; delete owner. 새 짝꿍은 연결 이전 사진을 볼 수 없다(look-back 0, 2026-10-03 결정 — 코드 수집·오연결 시 과거 사진 노출 차단).
- 첫 인증샷 전 1회 동의 시트(짝꿍 1명만 봄 / 위치 정보 제거 / 연결 끊으면 앱에서 더 이상 볼 수 없음 / 부적절한 사진 금지). 사진 뷰어에 `신고`·`연결 끊기`. 본인 인증샷 삭제.
- 서버 관계 트리거: `onRelationCreated`(1:1 서버 강제 — 위반 시 새 관계 삭제, 코드 1회용 재발급, 초대자 연결 푸시 1건, 초대자의 managerId 없는 active 약속에 짝꿍 지정), `onRelationDeleted`(양쪽 plans.managerId 해제, pending→active, 진행 중 내기 rejected, 코드 재발급).
- 탈퇴 정리: `auth.user().onDelete`에서 actions/cheers/Storage prefix/타인 plans의 managerId 정리.
- 최소 버전 게이트: `config/app {minBuild, latestBuild}`(공개 read) — minBuild 미만 차단 화면, latestBuild 미만 소프트 안내. 로그인 시 `users.clientBuild/timezone/locale` 기록.
- 푸시 호환: `data.type` 값 변경 금지. workoutType 있으면 운동 카피, 없으면 중립 카피. 인증샷 문구는 수신자 clientBuild가 피벗 빌드 이상일 때만. 구버전이 저장한 `실천 메이트` 똑똑 문구는 서버가 새 기본 문구로 대체. 인정 이중 푸시 제거. 마감 판정은 `users.timezone`(없으면 Asia/Seoul).
- action type·PlanState·PromiseStatus 값 추가 금지. 새 필드는 전부 optional.
- 기존 사용자 1회 공지: `'그래,해봐'가 둘운완이 됐어요. 약속, 기록, 짝꿍 연결은 그대로예요.`
- 권한 문구(ko/en 현지화): 카메라 `운동 인증샷을 찍어 연결된 짝꿍에게 보여주기 위해 카메라를 사용해요.` / 사진 `앨범에 있는 운동 사진을 인증샷으로, 또는 프로필 사진으로 올리기 위해 사진 보관함에 접근해요.`(모든 사용처 명시 — 5.1.1). 대외·인앱 개인정보 문구는 사실만: `인증샷은 짝꿍만 봐요`(Storage 규칙으로 보장). 기록 전체가 둘만 보인다는 주장은 읽기 규칙 축소(`firestore.rules.next`) 배포 전까지 금지.

## 6. 이번 릴리스 범위
포함: 위 1~5절 전부 + 버그 수정(인정이 엉뚱한 action에 기록, verifyHistoryItem lastUpdatedBy, 재시작 덮어쓰기, 승인 시 기간 리셋, rescue 버튼 숨김, 가짜 응원 버튼, 문자열 결합 로직 제거) + 집중 타이머·공부/검증 루틴·단방향 배지·테마 선택 숨김/제거 + 퍼널 계측(invite_shared, invite_code_detected, partner_connected{role}, proof_uploaded, partner_reacted, duo_done_day, share_card_shared, review_prompt_shown) + 스토어 자산(이름·아이콘·스플래시·메타데이터·캡션 스크린샷 6장·Play 피처 그래픽) + 개인정보처리방침/지원 페이지 + Hosting 초대 랜딩(`/i/{code}`).

다음 릴리스(문서화만): 홈/잠금 위젯(1순위), 카카오 FeedTemplate, Universal/App Link, 같이 했어(한 장으로 둘 다), D-day 목표, 주 N회 자유 요일, 내기 쿠폰·실행자 제안·서버 정산·verifiedDates 기준, 푸시 일일 상한, users/plans/actions read 축소 보안 묶음(minBuild 상향 후), 푸시 ko/en 분기, 짝꿍 사진 포함 공유 카드.

## 7. 스토어 메타데이터 (확정안, 길이 검증 필수)
- iOS ko 이름: `둘운완 - 커플 오운완 운동 인증` / 부제: `연인·부부 운동 약속, 다이어트 내기` / 키워드: `애인,남친,여친,짝꿍,챌린지,벌칙,홈트,헬스,습관,러닝,메이트,기록`
- iOS en 이름: `DuoDone: Couple Workout Proof` / 부제: `Partner-checked fitness habits` / 키워드: `accountability,partner,boyfriend,girlfriend,spouse,gym,habit,streak,challenge,bet,diet,photo`
- Play ko 제목: `둘운완: 커플 오운완 운동 인증` / en: `DuoDone: Couple Workout Proof`
- 기기 표시명: ko `둘운완`, en·기타 `DuoDone` (Guideline 2.3.8 토큰 일치).
- 스크린샷 순서: ① 짝꿍 인증샷 + ❤️ 인정(캡션 `둘이 보면, 진짜 하게 돼요`) ② 손가락 걸기(약속 1화면) ③ 오늘 운동했어?(인증샷) ④ 안 하면 짝꿍이 알아요(똑똑) ⑤ 못 지키면 치킨 쏘기(내기) ⑥ 둘이 함께 N일째(둘운완 보드). 로그인 화면 금지.

## 8. 완료 기준
- `flutter analyze` 에러 0, `flutter test` 전부 그린, `functions` `npm run build` 성공, 규칙 에뮬레이터 테스트 통과.
- iOS 시뮬레이터 빌드 성공 + 핵심 화면 스모크.
- 사용자 노출 문자열(ARB 값, lib, functions/src, ios/Runner, android/app/src/main)에서 `실천 메이트|공부|스터디|파일럿|Nod&Try|Nodtry|그래,해봐` 0건(키 이름·주석·레거시 호환 문자열 비교 제외).
- 메타데이터 길이 제한 준수, 표시명 토큰 일치.
- 배포(스토어 제출, Firebase rules/functions/hosting, 마이그레이션 실행, 광고 예산)는 대표 승인 후. 배포 순서: storage rules → firestore rules(config 읽기) → functions → hosting → 마이그레이션 dry-run/실행 → 앱 심사 제출(수동 출시) → 동시 공개.

## 9. 데이터 계약 (앱·서버 공통, 전부 optional·추가만)
- 피벗 빌드: `version: 1.1.0+81` → `PIVOT_BUILD = 81`.
- `plans/{id}`: `workoutType` (string: `gym|running|home_training|walking|pilates|yoga|stretching|swimming|climbing|cycling|hiking|strength|diet|other`), `lastActionId` (string, 마지막 done action 문서 ID), `lastProofPhotoPath` (string), `lastProofAt` (Timestamp).
- `actions/{id}`: `proofPhotoPath` (string `proofs/{uid}/{planId}/{actionId}.jpg`), `proofSource` (`camera|gallery`), `proofTakenAt` (Timestamp, 카메라=촬영 시각, 앨범=EXIF 원본 촬영일 있으면 그 값), `reaction` (string 이모지, 짝꿍이 인정할 때).
- `cheers/{id}`: 기존 필드 + `reactionType: 'reply'`(똑똑 원탭 답장, `message`에 답장 문구). 기존 `'poke'`/이모지 값 유지.
- `users/{uid}`: `clientBuild` (int), `timezone` (IANA string), `locale` (`ko|en`), `partnerNickname` (string ≤10자, 내가 짝꿍을 부르는 애칭), `pivotNoticeSeen` (bool, 선택 — 로컬 저장 우선).
- `config/app`: `{minBuild: int, latestBuild: int}` — 공개 read, 쓰기 금지(콘솔/admin만).
- 푸시 `data.type` 기존 값 유지. 신규 타입 추가 시 구버전이 무시해도 안전해야 함(`partner_connected`, `poke_reply`).
- Storage: `proofs/{ownerUid}/{planId}/{actionId}.jpg` (image/jpeg, <3MB).
