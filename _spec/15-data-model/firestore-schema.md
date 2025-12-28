# Firestore Data Model

## Collections

### `users`
사용자 기본 정보.
- **Document ID**: `uid` (Firebase Auth ID)
- **Fields**:
  - `displayName` (string): 표시 이름 (기본값: "나")
  - `email` (string?): 이메일 (익명인 경우 null)
  - `profileImageUrl` (string?): 프로필 이미지 URL
  - `statusMessage` (string?): 상태 메시지
  - `inviteCode` (string): 친구 초대 코드 (Unique, 8자리 난수)
  - `createdAt` (timestamp): 가입일
  - `updatedAt` (timestamp): 마지막 수정일
  - `isAnonymous` (boolean): 익명 계정 여부

### `relations`
사용자 간의 연결(Manage) 관계.
- **Document ID**: Auto-generated
- **Fields**:
  - `executorId` (string): 실행자(관리받는 사람) UID
  - `managerId` (string): 관리자(관리하는 사람) UID
  - `status` (string): 'pending' | 'active' | 'rejected'
  - `createdAt` (timestamp): 요청일
  - `connectedAt` (timestamp?): 수락일

### `plans` (Sub-collection of `users`?) -> `plans` (Root Collection)
권한 관리 및 조회가 쉽도록 Root Collection 권장.
- **Document ID**: Auto-generated
- **Fields**:
  - `userId` (string): 계획 소유자 UID
  - `managerId` (string?): 승인/관리하는 매니저 UID
  - `startDate` (timestamp): 시작일
  - `endDate` (timestamp): 종료일 (4주 뒤)
  - `state` (string): 'draft' | 'pending_approval' | 'active' | 'completed'
  - `items` (array of objects):
    - `title` (string)
    - `days` (array of int): [1, 3, 5] (월, 수, 금)
    - `count` (int): 주 N회
    - `notificationTime` (map?): 알림 설정 (Optional)
      - `type` (string): 'preset' | 'custom'
      - `value` (string): 'morning' | 'lunch' | 'dinner' | 'bedtime' | 'HH:mm'
      - `hour` (int): 0-23
      - `minute` (int): 0-59
  - `createdAt` (timestamp)

### `actions`
매일의 수행 기록 (History Tab의 소스).
- **Document ID**: Auto-generated
- **Fields**:
  - `userId` (string): 실행자 UID
  - `planId` (string): 관련 계획 ID
  - `date` (timestamp): 수행 날짜 (시간 제외, 00:00:00)
  - `type` (string): 'did_it' (했어) | 'skipped' (못했어)
  - `comment` (string?): 한마디
  - `verifiedBy` (string?): 확인해준 매니저 UID
  - `verifiedAt` (timestamp?): 확인 일시
  - `verificationComment` (string?): 매니저 코멘트
