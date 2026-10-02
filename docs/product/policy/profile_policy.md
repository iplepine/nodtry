<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 프로필(Profile)·우리 탭 정책

마지막 갱신: 2026-10-03 (1.1.0+81)

## 프로필 구성
| 항목 | 설명 | 비고 |
|---|---|---|
| 프로필 이미지 | 갤러리 선택 → 정사각형 크롭 → 업로드 | Storage `users/{uid}/` |
| 표시 이름 | 내 이름 | 기본값 `나` |
| 상태 메시지 | 한 줄 소개 | 선택 |
| 초대 코드 | 8자리, 서버가 연결·해제 때 회전 | [connect_policy.md](./connect_policy.md) |
| 짝꿍 애칭 | 내가 짝꿍을 부르는 호칭(≤10자) | [nickname_policy.md](./nickname_policy.md) |

## 프로필 이미지 업로드
1. 우리 탭 프로필 이미지 탭 → `image_picker` 갤러리 → `image_cropper` 정사각형 → Storage 업로드 → `users.profileImageUrl` 저장 → 로컬 캐시 갱신.
- 인증샷과 달리 프로필 이미지는 로그인 사용자 누구나 읽을 수 있다(짝꿍 아바타 표시).
- iOS 사진 권한 문구는 인증샷만 언급한다. PHPicker는 보통 권한 팝업이 없지만, 프로필 사진 언급 여부는 법무·제품 확인 대기.

## 프로필 업데이트
- `updateProfileUseCase.execute(name, statusMessage, imagePath)` → Firestore + 로컬 캐시(`userLocalDataSource.saveUser()`), `myProfileProvider`로 실시간 반영.
- 로그인 시 앱이 `clientBuild`·`timezone`·`locale`을 바뀐 값만 `update()`로 기록한다(문서가 없으면 만들지 않음).

## 우리 탭
### 히어로 (짝꿍 있을 때)
- `둘이 함께 N일째` + 이번 주 나/짝꿍 7일 도트(둘운완 데이 강조, 인정은 ❤️, 미스는 ×) + `공유 카드 만들기`. [duo_stats_policy.md](./duo_stats_policy.md)

### 내 섹션
- 프로필 이미지·이름·상태 메시지, 게스트 경고 배너, 내 약속 목록(active/pending)

### 짝꿍 섹션
- 짝꿍 카드: 애칭(크게) + 실제 이름(작게). 카드나 `애칭 정하기/바꾸기` 필을 탭하면 애칭 시트.
- 짝꿍 약속 목록(읽기 전용). 약속 제목에도 애칭 라벨.
- 연결 해제: `confirmAndDisconnectPartner` 공통 다이얼로그(인증샷 보기와 공유), 해제 시 사진 캐시 삭제.
- 숨김·제거: 단방향 배지(`지지받는 중`/`응원하는 중`) 숨김(양방향 배지만 유지), 가짜 응원 버튼 제거.

### 짝꿍 없을 때
- 초대 패널(공유·복사·코드 입력)

## 게스트
- 우리 탭 경고 배너 → 계정 연동(Google·이메일·Apple) 또는 탈퇴.
