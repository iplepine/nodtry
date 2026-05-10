# 설정(Settings) 정책

## 언어 설정
- 지원 언어: 한국어 (ko_KR), 영어 (en_US)
- Flutter localization (`flutter_localizations`) 사용
- `appSettingsProvider`에 저장 (Riverpod state)
- 변경 시 앱 전체 UI 언어 전환

## 테마 설정

| 테마 | 설명 |
|------|------|
| Mint × Orange (기본) | 민트 중심, 주황 행동 강조 색상 팔레트 |
| Deep Olive | 초록/올리브 색상 팔레트 |

- `AppTheme` enum + `ThemeData` 정의
- `appSettingsProvider`에 저장
- `MaterialApp.router`에서 watched theme 적용

## 계정 관리
- 회원 탈퇴: 확인 다이얼로그 → 전체 데이터 cascade 삭제 → 로그아웃 → 스플래시 화면

## 개발자 옵션
- `kDebugMode`에서만 표시
- 디버그용 Firebase 리셋, 데이터 초기화, 테스트 액션 등

## 인앱 결제 (IAP)

### 상품
- 커피 후원 (일회성 소모품)
- Product ID: `donation_coffee`
- 복수 구매 가능 (Consumable)

### IAP 상태 관리
- `iapServiceProvider` (NotifierProvider)
- 상태: `isAvailable`, `isPurchasing`, `purchaseError`, `products`

### 구매 흐름
1. `InAppPurchase.instance.isAvailable()` 확인
2. `donation_coffee` 상품 정보 조회
3. 구매 스트림 구독
4. 사용자가 구매 버튼 탭
5. `buyCoffee()` → 상품 검증 → 구매 시작
6. 스트림 리스너 처리:
   - Pending: 대기 상태
   - Success: 구매 완료 처리 (acknowledge)
   - Error: 에러 메시지 표시

### 에러 처리
- Firebase 에러 코드를 한국어 메시지로 매핑
- 토스트 알림으로 표시
