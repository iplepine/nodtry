# 화면 기능 명세: Now 탭 (Now Tab)

## 1. 개요
**Now 탭**은 사용자와 파트너의 현재 상태를 공유하고, "지금 해야 할 핵심 행동"을 실행하는 공간이다.

> 상세 로직 및 UI 스펙: [03-01-now-tab.md](../03-01-now-tab.md)

---

## 2. 제공 기능 목록 (Feature List)

### 2.1 내 행동 관리 (My Execution)
1. **지금 할 일 조회 (View Now Action)**
   - 현재 시간에 가장 임박하거나 진행 중인 단 하나의 계획을 확인한다.
2. **실천 완료 처리 (Complete Action)**
   - 계획을 실천하고 완료 상태로 변경한다. (`했어` 버튼)
3. **실천 미루기/스킵 (Skip Action)**
   - 지금 실천하지 않고 넘어가거나 미룬다. (추후 구현 / `오늘은 넘어가자`)
4. **지난 실천 소명 (Reconcile Overdue)**
   - 제때 처리하지 못한 과거의 할 일을 뒤늦게 완료하거나 쉬었음을 기록한다.

### 2.2 파트너 소식 (Partner Awareness)
5. **파트너 계획 수신 (Receive Partner Plan)**
   - 파트너가 새로 생성하거나 제안한 계획을 확인한다.
6. **파트너 실천 확인 (Acknowledge Partner Action)**
   - 파트너가 완료한 실천 기록을 조회하고 "확인/응원" 반응을 보낸다.

### 2.3 상태/정보 (Status & Info)
7. **빈 상태 안내 (Empty State Guide)**
   - 할 일이 없을 때(Plan Needed) 또는 모두 완료했을 때(Today Done/Relaxed) 현재 상황에 맞는 안내 메시지를 제공한다.

### 2.4 디버그 (Debug - Dev Only)
8. **시나리오 전환 (Switch Scenario)**
   - (Mock 모드) 다양한 카드 상태를 강제로 전환하여 테스트한다.
