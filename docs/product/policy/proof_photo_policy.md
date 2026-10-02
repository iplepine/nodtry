# 인증샷(Proof Photo) 정책

마지막 갱신: 2026-10-03 (1.1.0+81, 피벗 S4·backend) · 스펙 §4.4~4.5, §5 · 사용자 용어 `오운완 인증` / 사진이 있으면 `인증샷`

## 원칙
- 사진은 **연결된 짝꿍 1명만** 본다. 공개 피드·공유 링크 없음.
- 위치(GPS)·기기 정보(EXIF)는 올리기 전에 **기기에서** 전부 지운다. 원본은 서버로 가지 않는다.
- Firestore에는 **Storage 경로만** 저장한다. 다운로드 URL 저장 금지(URL은 규칙을 우회하는 영구 링크가 된다).
- 사진은 선택이다. 실패해도 오늘 기록은 남는다.

## 촬영·업로드 흐름 (`proof_capture.dart`)
1. **첫 사진 1회 동의 시트** — `연결된 짝꿍 한 명만 볼 수 있어요.` / `위치 정보 같은 사진 정보는 지우고 올려요.` / `연결을 끊으면 앱에서 더 이상 볼 수 없어요.` / `부적절한 사진은 올리지 말아 주세요.` 동의는 `proof.consent_accepted_v1`(SharedPreferences, 기기 단위). 거절하면 사진 없이 끝.
2. **출처 시트** — `📸 카메라`(먼저, 강조) / `🖼️ 앨범`. `image_picker` maxWidth/maxHeight 1440, quality 85.
3. **기기 처리** (`processProofPhotoBytes`, isolate) — 디코드 → EXIF 촬영 시각 읽기(DateTimeOriginal → Digitized → DateTime) → 방향 반영 → 긴 변 1440px → **빈 EXIF로 JPEG 재인코딩**. 해독 불가(일부 HEIC 등)면 토스트, 사진 없음.
4. **미리보기** — 사진 + 출처 배지 + 한마디(선택, 자동 포커스 없음) → `인증하기`.
5. **저장 순서** — action id 선할당 → Storage `proofs/{uid}/{planId}/{actionId}.jpg`(`image/jpeg`) 업로드 → plan + action을 **한 배치**로 쓴다.
   - plan: `completedDates`, `lastActionNote`, `lastActionId`, (사진 성공 시) `lastProofPhotoPath`, `lastProofAt`
   - action: `proofPhotoPath`, `proofSource`(`camera|gallery`), `proofTakenAt`(알 때만)
6. **실패** — 업로드 8초 타임아웃(업로드 취소) 또는 오류면 사진 필드 없이 기록하고 `사진은 못 올렸지만 오늘 기록은 남겼어요.`

### 촬영 시각 (`proofTakenAt`)
- 카메라: 지금 시각. 앨범: EXIF 원본 촬영일이 있으면 그 값, 없으면 비움.

## 보기 (`ProofPhoto`, `proof_photo_view.dart`)
- 경로로 `ref.getData()`(최대 3.5MB). `ProofPhotoCache`: 메모리 LRU + 디스크(`<tmp>/proof_photos`, 경로 sha1 키), 동시 요청 1회로 합침.
- 출처 배지: `📸 방금 찍음 · 19:42`(오늘 카메라) / `📸 카메라 · 9/28 19:42` / `🖼️ 앨범 · 9/28 촬영` / `🖼️ 앨범`(날짜 모름). 짝꿍 카드는 배지를 위해 `actions/{lastActionId}`를 1회 더 읽는다.
- **오늘 사진 판정**: `lastProofAt`이 오늘이고 경로가 `lastActionId`와 일치할 때만(`todayProofPhotoPathOf`). 어제 사진은 오늘 인증으로 보이지 않는다.
- 탭 → 전체 화면(InteractiveViewer) + 메뉴:
  - `신고하기` → `devhohouse@gmail.com` 메일 초안(action ID 포함). 메일 앱이 없으면 주소 토스트.
  - `연결 끊기` → 공통 해제 다이얼로그.
  - `사진 삭제` → 본인만.

## 삭제
- 본인 삭제(`deleteProofPhoto`): Storage 객체 삭제 → action의 사진 필드 삭제 → 그 사진이 plan의 최신 사진이면 `lastProofPhotoPath`·`lastProofAt`도 삭제. 기록 자체는 남는다.
- 연결 해제: 서버가 `managerId`를 지우는 순간 Storage 규칙상 전 짝꿍은 읽기 불가. 양쪽 기기의 캐시를 지운다(해제 다이얼로그 직후, 상대가 해제한 경우, 앱이 미연결 상태로 시작한 경우, 계정 변경 시).
- 회원 탈퇴: 서버가 `proofs/{uid}/` 전체 삭제.

## 인정과 연결
- 짝꿍 카드·기록 카드에 사진 + ❤️🔥💪👏 원탭 → `actions.reaction` + `verifiedDates`. 인정 후 내 `todayComplete` 카드에 `짝꿍이 인정했어요`.
- 짝꿍 빌드 ≥ 81이면 서버가 `📸 {이름} 오운완 인증샷 도착!` 푸시(아니면 일반 완료 푸시).

## Storage 규칙 (`storage.rules` `proofs/{ownerUid}/{planId}/{fileName}`)
- read: 본인 또는 `plans/{planId}.managerId == auth.uid`(현재 짝꿍)
- create: 본인 && `resource == null` && `image/jpeg` && < 3MB && `plans/{planId}.userId == 본인`. action 문서 존재는 요구하지 않는다(업로드가 먼저).
- update: 금지 · delete: 본인
- 교차 서비스 규칙이라 첫 `firebase deploy --only storage` 때 IAM 권한 부여를 **수락해야** 한다. 거절하면 모든 업로드·조회가 거부된다. `docs/operations/SECURITY_RULES.md`

## 분석
- `proof_uploaded {has_photo, source: camera|gallery|none}` — 모든 했어 기록마다. `has_photo=0, source=camera`는 업로드 실패.
- `partner_reacted {latency_bucket, surface: now|now_note|history|history_note, reaction, has_photo}`
- `plan_completed {has_message, has_photo}`

## 알려진 한계
- 사진이 있으면 Firestore 배치 전에 업로드하므로 나쁜 회선에서 최대 약 8초 걸린다. 카드는 바로 줄어들지만 진행 표시가 없다.
- 기기 처리 0.5~1.5초(중급 기기 추정), 실기기 미검증. iPhone HEIC 앨범 사진 실기기 확인 필요.
- 구버전이 같은 날 다시 기록하면 `lastActionId`를 갱신하지 않아, 짝꿍이 그날 앞선 사진을 볼 수 있다.
- 짝꿍이 원격으로 연결을 끊어도 이미 열린 전체 화면 보기는 닫히지 않는다.
- Android 11+ 일부 기기는 메일 초안을 위해 `<queries>` mailto 항목이 필요할 수 있다(미추가).
- `history_state.freezed.dart`의 `reaction` 필드는 build_runner 고장으로 손으로 추가했다. 고친 뒤 재생성해 diff가 없는지 확인.
