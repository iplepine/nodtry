# 똑똑(Poke) 정책

## 개요
파트너의 상태에 따라 "똑똑! 하기" 버튼을 노출하여 행동을 유도하는 기능.

## 똑똑 유형

### 1. partnerNoPlan (파트너 계획 없음)
- **조건**: 파트너에게 active/pendingApproval/rejected 상태의 플랜이 하나도 없을 때
- **노출 위치**: 지금 탭 > Manager Card
- **메시지**: "상대방이 아직 새로운 약속을 만들지 않았어요. 똑똑! 신호를 보내볼까요?"
- **버튼**: "똑똑! 하기"

### 2. partnerPoke (파트너 실천 지연)
- **조건**: 파트너에게 오늘 해야 할 일이 있는데 아직 완료하지 않았을 때
- **노출 위치**: 지금 탭 > Manager Card
- **메시지**: "{파트너명}님이 아직 소식이 없어요. 똑똑! 하고 깨워볼까요?"
- **버튼**: "똑똑! 하기"

## 방향 정책 (2025-03-25 적용)

### 양방향 똑똑
- Manager든 Executor든 관계 방향에 **무관하게** 파트너의 플랜 상태를 체크
- 같은 파트너를 중복 체크하지 않음 (`checkedPartnerUids` Set으로 관리)
- 이유: 관계가 상호적이므로 똑똑도 양방향이 자연스러움

### 구현 위치
- 카드 생성: `real_record_repository.dart` > `_processPlans()` > Part 3
- UI 렌더링: `now_tab_screen.dart` > `_ManagerQuickCard`
- Intent 처리: `now_tab_viewmodel.dart` > `PokeUserIntent`, `PokePartnerIntent`

## 노출 위치 참고
- **지금 탭**: Manager Card에서 똑똑 버튼 노출 (O)
- **우리 탭**: "파트너가 진행 중인 약속이 없어요" 텍스트만 표시 (똑똑 버튼 없음)
