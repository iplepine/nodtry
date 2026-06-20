<!-- COMMIT_STATUS START -->
> **커밋 상태**
> - 기준 커밋: `1277a2680ab04f613f222378000af41a3979ca6a` (`main`)
> - 최근 커밋: `1277a2680ab0` docs: refresh project documentation status
> - 커밋 일시: `2026-06-20T22:38:59+09:00`
> - 워킹트리: `dirty (20 files)`
> - 문서 갱신: `2026-06-20 22:39:28 +0900`
<!-- COMMIT_STATUS END -->

# 관계(Relation) 정책

## 관계 구조

### Relation 모델
- `managerId`: 관리자(응원하는 사람)
- `executorId`: 실천자(지지받는 사람)
- `status`: pending | active | rejected

### 관계 유형 (UI 뱃지)
| 조건 | 뱃지 | 의미 |
|------|------|------|
| 나=Executor, 상대=Manager (1개 relation) | 지지받는 중 | 상대가 나를 응원 |
| 나=Manager, 상대=Executor (1개 relation) | 응원하는 중 | 내가 상대를 응원 |
| 양방향 relation 2개 존재 | 함께하는 중 | 상호지지 |

## 연결 정책

### 파트너 연결 시 양방향 relation 생성 (2025-03-25 적용)
- `connectWithCode` 호출 시 relation 2개를 batch로 생성
  - A: 초대자(코드 생성자) = Manager, 참여자(코드 입력자) = Executor
  - B: 참여자 = Manager, 초대자 = Executor
- 결과: 연결 즉시 **상호지지(함께하는 중)** 상태
- 이유: 파트너 연결은 본질적으로 상호 관계이므로 단방향은 부자연스러움

### 기존 단방향 관계 마이그레이션
- 기존 사용자는 relation이 1개만 존재할 수 있음
- 해결 방법: Firebase `relations` 컬렉션에서 기존 문서 삭제 후 앱에서 재연결
- 앱 로직(똑똑 등)은 양방향 체크로 단방향 관계도 호환
