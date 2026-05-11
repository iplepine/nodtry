# Nodtry Icon Guide

직접 제작한 아이콘 asset은 사용하지 않는다.
앱 내부 아이콘은 Flutter Material Icons의 rounded/outlined 계열을 우선 사용하고, Nodtry의 성격은 아이콘 자체보다 색상, 배경칩, 카드 상태로 표현한다.

## 원칙

- 기본 크기: 18, 20, 24 중 하나
- 기본 색상: `AppColors.textPrimary`, `AppColors.textSecondary`
- 긍정/완료: 민트 계열
- 호출/주의/똑똑: 주황 계열
- 아이콘 단독 장식보다 버튼, 카드, 상태칩 안에서 사용한다.
- 앱 런처 아이콘과 스플래시는 별도 제작 대상으로 둔다.

## 매핑

| 의미 | Flutter 아이콘 | 사용처 |
| --- | --- | --- |
| 똑똑 | `Icons.touch_app_rounded` | 똑똑 CTA, 상대방 호출 |
| 약속 카드 | `Icons.fact_check_rounded` | 약속 목록, 약속 카드 |
| 오늘 완료 | `Icons.check_circle_rounded` | 오늘 완료, 전체 완료 카드 |
| 확인하고 응원 | `Icons.chat_bubble_rounded` | 응원/피드백 CTA |
| 상 | `Icons.emoji_events_rounded` | 상과벌 보상 |
| 벌 | `Icons.flag_rounded` | 상과벌 벌칙 |
| 약속 걸기 | `Icons.handshake_rounded` | 약속 제안 CTA |
| 약속 대기 | `Icons.hourglass_bottom_rounded` | 수락 대기 상태 |
| 조율하기 | `Icons.tune_rounded` | 계획 조율, 반려 사유 |
| 휴식권 | `Icons.nightlight_round` | 오늘은 쉬어갈게요 |
| 놓친 약속 | `Icons.schedule_rounded` | 지연, overdue |
| 다시 당기기 | `Icons.replay_rounded` | 복귀, 다시 시도 |
| 관계 연결 | `Icons.link_rounded` | 연결/초대 |
| 파트너 | `Icons.person_rounded` | 상대 프로필 fallback |
| 우리 | `Icons.group_rounded` | 우리 탭 |
| 기록 | `Icons.timeline_rounded` | 기록 탭 |
| 빈 상태 | `Icons.add_task_rounded` | 약속 없음 |
| 실천 인정 | `Icons.volunteer_activism_rounded` | rescue |
