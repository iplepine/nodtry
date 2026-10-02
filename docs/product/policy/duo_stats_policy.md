<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `ca33b3afce18d181a507f9c3b524991d4fdbb21a` (`feat/couple-workout-pivot`)
> - 최근 커밋: `ca33b3afce18` docs: 둘운완 pivot spec, decision D-007, launch plan and runbook
> - 커밋 일시: `2026-10-03T07:18:28+09:00`
> - 워킹트리: `dirty (30 files)`
> - 문서 갱신: `2026-10-03 07:18:59 +0900`
<!-- COMMIT_STATUS END -->

# 둘운완(Duo Stats)·공유 카드·평점 요청 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S6) · 스펙 §4.7~4.8, §4.10 · 결정 D-007

## 정의
**둘운완 데이** = 두 사람 모두 그날 **미스가 없고**, 적어도 한 명이 **done**인 날. 인정은 조건이 아니라 ❤️ 보너스다.
서버 필드가 아니라 클라이언트가 두 사람의 약속에서 매번 계산한다(`computeDuoStats`, 순수 함수).

## 개인별 하루 판정 (`duoPersonDayOf`)
| 상황 | 상태 |
|---|---|
| 예정일 + done | `done` (OK) |
| 예정일 + 휴식권 | `rested` (OK) |
| 예정일 + 인정받은 rescue | OK |
| 예정일 + 건너뜀 또는 기록 없음(지난 날) | `missed` (미스) |
| 오늘 예정 + 아직 기록 없음 | `pending` (연속을 끊지 않음) |
| 미래 예정일 | `upcoming` |
| 비예정일 | `off` (중립) |
| 비예정일인데 운동 기록함 | `done`으로 센다 |

- 같은 날 약속이 2개면 **둘 다** 채워야 OK.
- 예정 판단은 active·completed 약속의 기간 안 요일만. **stopped 약속은 중단일이 없어 미스를 만들지 않는다**(done은 센다).
- done의 인정 표시: `verified`(인정받음) / `waiting`(인정 대기) / `none`(혼자 약속).

## 연속 일수 (streak)
- 오늘부터 과거로(최대 730일) 거슬러 간다.
- **오늘은 끊지 않는다**: 진행 중이면 건너뛰고, 오늘이 둘운완이면 센다.
- 둘 다 `off`인 날은 건너뛴다(끊지도 세지도 않음).
- **휴식권만 있는 날도 건너뛴다**(끊지도 세지도 않음). 휴식권이 실제로 연속을 지켜 준다.
- 어느 한쪽이라도 미스가 있으면 끊긴다.
- 예: A 월수금 + B 화목, 둘 다 빠짐없이 함 → 평일 5일 연속.

## 반환값 (`DuoStats`)
`streak`, `streakStart`, `today`, `week`(월~일, 나/짝꿍), `hasPartner`, `todayIsDuoDone`, `weekDuoDays`.
`duoStatsProvider`는 두 사람의 약속 스트림이 모두 들어오기 전엔 null이다.

## 노출
- **지금 탭 헤더**: 두 아바타 + `둘이 함께 N일째`(0이면 `오늘 둘 다 하면 둘운완 1일째`) + 각자 상태 칩(`나 인정 대기`, `{애칭} 아직` 등). 둘운완 데이면 `오늘 둘운완이에요 🎉`.
- **우리 탭 히어로**: 연속 일수 + 이번 주 나/짝꿍 도트(둘운완 데이 강조, 인정 ❤️, 미스 ×) + `공유 카드 만들기`.
- **기록 탭 주간 펄스**: 같은 통계.
- 짝꿍이 없으면 표시하지 않는다.

## 공유 카드 (`duo_share_card.dart`)
- 9:16, 360×640 레이아웃 → RepaintBoundary로 1080×1920 PNG.
- 내용: **내 최신 인증샷**(없으면 그날 운동 이모지 + 브랜드 그라데이션), `#둘운완 연속 N일`, `나 ✓ 🏃 러닝` / `{애칭} ✓ 🏋️ 헬스`, 날짜, 푸터 `App Store·Google Play에서 둘운완`.
- **짝꿍 사진은 넣지 않는다**(동의 이슈), 짝꿍 실명도 넣지 않는다(애칭 또는 `짝꿍`).
- 시트는 바로 열리고 내 사진은 안에서 불러온다(4초 제한). `share_plus`로 공유.
- 제안 시점(`decideDuoShareOffer`): 오늘이 둘운완 데이가 되면 **하루 1회**, 연속 3·7·30일 마일스톤은 연속 구간당 1회 축하 문구. 우리 탭 버튼으로 수동 공유.
- 분석: `duo_done_day {streak}`(기기당 하루 1회), `share_card_shared {target: kakao|instagram|save|copy|other|unknown, trigger: today|milestone|manual, streak}`. `unknown`은 공유로 센다.

## 평점 요청 (`review_prompt.dart`)
- `in_app_review`. 첫 둘운완 데이 후, 받은 인정 3회째 후. 기기당 최대 3회(`review.prompt_count_v1`, `review.prompt_fired_v1`).
- 공유 시트가 닫힌 뒤에만 요청, 기다리지 않음, 오류 무시. 기능을 막지 않는다. OS가 실제 표시 여부를 정한다.
- 분석: `review_prompt_shown {trigger: first_duo_day|third_props, count}`

## 기기 저장 키
`duo.share_offered_day_v1`, `duo.share_milestones_v1`, `duo.done_day_logged_v1`, `review.prompt_count_v1`, `review.prompt_fired_v1`

## 결정 대기·한계
- **공유 카드 빈도**(대표 결정): 지금은 스펙 문자 그대로 둘운완 데이마다 하루 1회. 활발한 커플은 거의 매일 시트를 본다. 첫 둘운완 데이 + 3/7/30 마일스톤만으로 줄이려면 `decideDuoShareOffer`만 바꾸면 된다.
- **푸터 문구**: `Google Play`가 iOS 앱 화면·스크린샷에 나오면 Apple 가이드라인 2.3.10 위험. 플랫폼 중립 문구(예: `스토어에서 '둘운완' 검색`)로 바꾸는 것이 권고(미반영).
- 업데이트 직후 기존 사용자 중 인정 3회 이상이거나 연속 중인 사람은 첫 실행에 평점 요청을 볼 수 있다(최대 3회, OS 제한).
- 짝꿍의 모든 약속을 `userId`로 읽는다. plans read 규칙을 좁히면 쿼리가 통째로 거부되므로 보안 묶음 때 함께 바꾼다.
- stopped 약속은 미스를 만들지 않아, 미스 뒤에 중단하면 그 미스가 연속 계산에서 빠진다.
