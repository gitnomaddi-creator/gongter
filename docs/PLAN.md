# 공터 (Gongter) 구현 계획

> **기준 문서**: PRD_v1.1.md
> **현재 상태**: PRD 갭 해소 중 (단계 1~6 완료)
> **작성일**: 2026.03.02
> **최종 수정**: 2026.03.05
> **총 단계**: 15단계 (12단계 완료, 3단계 남음)

---

## 현황 요약

### 구현 완료
- Supabase 프로젝트 + DB 스키마 + 243개 지자체 시드
- 이메일 인증 (가입/로그인/OTP/비밀번호 재설정)
- 홈 (내 지자체 피드 + 전국 HOT + 태그 필터)
- 게시글 CRUD + 이미지 업로드
- 댓글 작성/삭제/수정 + 대댓글 1depth + soft delete
- 좋아요/북마크 (RPC atomic toggle)
- 신고/차단 (클라이언트 + RLS 양방향)
- 탐색 (지자체별 피드 + 게시글 검색)
- 프로필 (내 글/댓글/북마크/닉네임 변경)
- 설정 (로그아웃/계정삭제/법적고지/차단목록)
- AdMob 배너 + 전면광고 (테스트 ID)
- ATT + FCM 기본 구조
- GitHub Pages (이용약관/개인정보처리방침)
- Android 릴리즈 서명 (keystore)
- 금칙어 필터링 (글/댓글/수정 전체)
- 닉네임 중복 허용 + 탈퇴 사용자 익명화

### PRD 대비 남은 갭
| # | 항목 | 상태 | 우선순위 |
|---|---|---|---|
| 7 | 온보딩 화면 | 미구현 | 중간 |
| 8 | 이메일 도메인 화이트리스트 강화 | `.kr` 느슨한 검증 | 높음 |
| 9 | 소속 변경 문의 | 미구현 | 낮음 |
| 10 | 이미지 용량 제한 | 상수만 선언, 검증 없음 | 중간 |
| 11 | 포그라운드 FCM 알림 | debugPrint만 | 중간 |
| 12 | AdMob 실제 ID + 네이티브 광고 | 테스트 ID, 네이티브 없음 | 출시 전 필수 |
| 13 | iOS 빌드 | 미진행 | 출시 전 필수 |
| 14 | 출시 전 최종 점검 | 미진행 | 출시 전 필수 |
| 15 | 출시 준비 (스크린샷/메타데이터/제출) | 미진행 | 최종 |

---

## 단계 1: 코드 버그 수정 ✅

- **만들 파일**: 없음 (기존 파일 수정)
- **수정할 파일**:
  - `lib/screens/auth/signup_screen.dart`
  - `lib/screens/auth/profile_setup_screen.dart`
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/profile/profile_screen.dart`
- **할 일**:
  1. `DropdownButtonFormField`의 `initialValue` → `value`로 변경 (signup_screen, profile_setup_screen, settings_screen 총 6곳)
  2. `profile_setup_screen.dart`에 닉네임 정규식 검증 추가 (`^[가-힣a-zA-Z0-9]+$`)
  3. `profile_screen.dart` 닉네임 변경 다이얼로그에서 `validateNickname()` 호출 추가 + 정규식 검증 추가
- **의존성**: 없음 (가장 먼저 진행)
- **완료 기준**: `flutter analyze` 에러 없음 + 회원가입/프로필설정/설정 화면에서 드롭다운이 정상 동작
- **검증 방법**: 앱 실행 → 회원가입 Step 2에서 시/도·시/군/구 드롭다운 선택 동작 확인 + 닉네임에 특수문자 입력 시 에러 표시 확인
- **예상 소요**: 15분

---

## 단계 2: 댓글 soft delete (대댓글 보존) ✅

- **만들 파일**: 없음
- **수정할 파일**:
  - Supabase SQL (Dashboard 또는 migration 파일)
  - `lib/services/supabase_service.dart`
  - `lib/screens/post/post_detail_screen.dart`
- **할 일**:
  1. Supabase에 `soft_delete_comment` RPC 함수 생성:
     - 대댓글(parent_id = 해당 comment.id)이 있으면 → `is_deleted = true`, `content = ''` 으로 업데이트
     - 대댓글이 없으면 → 물리 삭제 (DELETE)
  2. `supabase_service.dart`의 `deleteComment()` 메서드를 RPC 호출로 변경
  3. `post_detail_screen.dart`에서 `is_deleted == true`인 댓글의 답글/좋아요/신고 버튼 숨김 처리 (이미 부분 구현됨, 확인만)
- **의존성**: 없음
- **완료 기준**: 대댓글이 있는 댓글 삭제 시 "삭제된 댓글입니다"로 표시되고 대댓글은 유지됨
- **검증 방법**:
  - 테스트 계정으로 댓글 A 작성 → A에 대댓글 B 작성 → A 삭제
  - A가 "삭제된 댓글입니다"로 표시, B는 그대로 유지 확인
  - 대댓글 없는 댓글 삭제 시 완전히 사라지는지 확인
- **예상 소요**: 20분

---

## 단계 3: 양방향 차단 RLS 구현 ✅

- **만들 파일**: 없음
- **수정할 파일**:
  - Supabase SQL (RLS 정책 수정)
- **할 일**:
  1. `posts_select` RLS 정책에 차단 필터 추가:
     ```
     author_id NOT IN (SELECT blocked_id FROM blocks WHERE blocker_id = auth.uid())
     AND author_id NOT IN (SELECT blocker_id FROM blocks WHERE blocked_id = auth.uid())
     ```
  2. `comments_select` RLS에 동일 필터 추가
  3. 성능을 위해 `blocks` 테이블에 양방향 인덱스 확인 (`idx_blocks_blocker` 이미 존재, `idx_blocks_blocked` 추가 필요)
  4. 클라이언트의 기존 `_blockedUserIds` 필터링은 **유지** (이중 안전장치)
- **의존성**: 없음
- **완료 기준**: 차단한/차단당한 사용자의 글과 댓글이 DB 레벨에서 필터링됨
- **검증 방법**:
  - Supabase Dashboard에서 SQL 쿼리로 검증:
    - 사용자 A가 B를 차단 → A 세션으로 posts 조회 시 B의 글 미포함 확인
    - B 세션으로 posts 조회 시 A의 글 미포함 확인 (양방향)
  - 앱에서 차단 후 피드/검색에서 해당 사용자 글 미노출 확인
- **예상 소요**: 20분

---

## 단계 4: 금칙어 필터링 (글/댓글 작성 시) ✅

- **만들 파일**: 없음
- **수정할 파일**:
  - `lib/services/supabase_service.dart`
  - `lib/screens/post/post_write_screen.dart`
  - `lib/screens/post/post_edit_screen.dart`
  - `lib/screens/post/post_detail_screen.dart` (댓글 작성 부분)
- **할 일**:
  1. `supabase_service.dart`에 `validateContent(String text)` 메서드 추가:
     - `banned_words` 테이블에서 abuse/obscene 카테고리 단어 조회
     - 텍스트에 금칙어 포함 여부 반환
  2. `post_write_screen.dart`의 `_submit()`에서 제목+내용 금칙어 검증 추가
  3. `post_edit_screen.dart`의 `_submit()`에서 동일 검증 추가
  4. `post_detail_screen.dart`의 `_submitComment()`에서 댓글 내용 금칙어 검증 추가
  5. 금칙어 감지 시 SnackBar로 "부적절한 표현이 포함되어 있습니다" 안내
- **의존성**: 없음
- **완료 기준**: 금칙어가 포함된 글/댓글 작성 시 제출이 차단되고 안내 메시지 표시
- **검증 방법**:
  - `banned_words` 테이블에 테스트 단어 추가
  - 해당 단어를 포함한 글 작성 시도 → 차단 확인
  - 해당 단어를 포함한 댓글 작성 시도 → 차단 확인
  - 정상 텍스트는 문제없이 작성되는지 확인
- **예상 소요**: 25분

---

## 단계 5: 닉네임 중복 허용 + 계정 삭제 익명화 개선 ✅

- **만들 파일**: 없음
- **수정할 파일**:
  - `lib/services/supabase_service.dart`
  - Supabase SQL (`delete_my_account` RPC 수정)
- **할 일**:
  1. **닉네임 중복 허용**: `validateNickname()` 메서드에서 중복 체크 로직 제거 (금칙어 검사만 유지)
     - PRD 3.7절: "중복 허용 (UNIQUE 불필요)"
  2. **계정 삭제 익명화 개선**: `delete_my_account` RPC 수정
     - 현재: `author_id = NULL` → 변경: 시스템 UUID (예: `'00000000-0000-0000-0000-000000000000'`)로 설정
     - 또는 `author_id = NULL` 유지하되, 클라이언트에서 `author_id IS NULL`일 때 "탈퇴한 사용자" 표시
     - post_card.dart, post_detail_screen.dart에서 `authorId == null` 시 "탈퇴한 사용자" 라벨 처리
- **의존성**: 단계 1 (닉네임 검증 로직과 관련)
- **완료 기준**: 닉네임 중복으로 설정 가능 + 계정 삭제 후 해당 사용자의 글/댓글이 "탈퇴한 사용자"로 표시
- **검증 방법**:
  - 두 계정에서 같은 닉네임 설정 → 에러 없이 성공 확인
  - 테스트 계정 삭제 후 해당 사용자의 글/댓글에 "탈퇴한 사용자" 표시 확인
- **예상 소요**: 20분

---

## 단계 6: 댓글 수정 기능 ✅

- **만들 파일**: 없음
- **수정할 파일**:
  - `lib/services/supabase_service.dart`
  - `lib/screens/post/post_detail_screen.dart`
- **할 일**:
  1. `supabase_service.dart`에 `updateComment()` 메서드 추가:
     ```
     updateComment({required String commentId, required String content})
     ```
  2. `post_detail_screen.dart`의 `_buildCommentTile()`에 내 댓글 "수정" 버튼 추가 (삭제 버튼 옆)
  3. 수정 탭 시 인라인 수정 또는 다이얼로그 표시
  4. 수정 시 금칙어 검증 적용 (단계 4 메서드 재사용)
  5. `isEdited == true`인 댓글에 "수정됨" 표시 (DB 트리거 이미 존재)
- **의존성**: 단계 4 (금칙어 검증 재사용)
- **완료 기준**: 내 댓글 수정 가능 + 수정된 댓글에 "수정됨" 표시
- **검증 방법**:
  - 댓글 작성 → 수정 버튼 탭 → 내용 변경 → 저장
  - "수정됨" 라벨 표시 확인
  - 금칙어 포함 수정 시 차단 확인
  - 다른 사용자 댓글에는 수정 버튼 미노출 확인
- **예상 소요**: 25분

---

## 단계 7: 온보딩 화면

- **만들 파일**:
  - `lib/screens/onboarding/onboarding_screen.dart`
- **수정할 파일**:
  - `lib/router.dart` (온보딩 라우트 추가)
  - `lib/main.dart` (SharedPreferences로 온보딩 완료 여부 체크)
- **할 일**:
  1. `onboarding_screen.dart` 생성:
     - 2~3 페이지 PageView (스와이프)
     - 페이지 1: 앱 소개 ("38만 지방공무원의 익명 마당")
     - 페이지 2: 핵심 기능 안내 (피드, 검색, 익명)
     - 페이지 3: 공무원법 주의사항 + "시작하기" 버튼
  2. `router.dart`에 `/onboarding` 라우트 추가
  3. redirect 로직에 온보딩 미완료 시 `/onboarding`으로 리다이렉트 추가
  4. SharedPreferences에 `onboarding_complete` 플래그 저장
  5. 온보딩 완료 → `/login` 또는 `/signup`으로 이동
- **의존성**: 없음 (독립)
- **완료 기준**: 첫 설치 시 온보딩 화면 표시 → 완료 후 다시 안 나타남
- **검증 방법**:
  - 앱 데이터 초기화 후 실행 → 온보딩 화면 표시 확인
  - 온보딩 완료 후 재실행 → 로그인 화면으로 바로 이동 확인
  - 각 페이지 스와이프 동작 확인
- **예상 소요**: 30분

---

## 단계 8: 이메일 도메인 화이트리스트 강화

- **만들 파일**:
  - `lib/utils/email_validator.dart` (도메인 검증 로직 분리)
- **수정할 파일**:
  - `lib/screens/auth/signup_screen.dart` (88~91행의 느슨한 검증 교체)
  - `lib/services/supabase_service.dart` (도메인 목록 조회 메서드 추가)
- **할 일**:
  1. `email_validator.dart` 생성:
     - `isAllowedDomain(String email)` 메서드
     - 기본 허용: `.go.kr` 전체 (korea.kr, onnara.go.kr, 각 지자체.go.kr 포함)
     - municipalities 테이블의 `email_domain` 컬럼도 화이트리스트로 활용
     - 일반 `.kr` 도메인 차단 (naver.kr, daum.kr 등)
  2. `supabase_service.dart`에 `getEmailDomainWhitelist()` 추가:
     - `SELECT DISTINCT email_domain FROM municipalities WHERE email_domain IS NOT NULL`
     - 메모리 캐시 (앱 실행 시 1회 로드)
  3. `signup_screen.dart` 88~91행 교체:
     - 기존: `!email.endsWith('.go.kr') && !email.endsWith('.kr')`
     - 변경: `EmailValidator.isAllowedDomain(email)` 호출
     - 에러 메시지: `'공무원 이메일만 사용 가능합니다 (go.kr, korea.kr 등)'`
- **의존성**: 없음 (독립)
- **완료 기준**: `naver.kr` 등 일반 `.kr` 이메일 차단 + `seoul.go.kr`, `korea.kr`, `onnara.go.kr` 등 공무원 이메일만 통과
- **검증 방법**:
  - `test@naver.kr` 입력 → 에러 메시지 표시
  - `test@seoul.go.kr` 입력 → 통과
  - `test@korea.kr` 입력 → 통과
  - `test@onnara.go.kr` 입력 → 통과
  - `test@gmail.com` 입력 → 기존대로 차단
- **예상 소요**: 20분

---

## 단계 9: 소속 변경 문의 버튼

- **만들 파일**: 없음
- **수정할 파일**:
  - `lib/screens/settings/settings_screen.dart`
- **할 일**:
  1. 설정 화면 "계정" 섹션에 "소속 변경 문의" `ListTile` 추가 (로그아웃 위):
     - 아이콘: `Icons.swap_horiz`
     - subtitle: `'인사이동 시 소속 변경이 필요하면 문의해주세요'`
     - onTap: `mailto:nomad.webapp@gmail.com?subject=[공터] 소속 변경 문의` URI 실행
     - `url_launcher` 이미 import 되어 있음
  2. 기존 관리자 전용 "지자체 변경" 메뉴는 그대로 유지
- **의존성**: 없음 (독립)
- **완료 기준**: 설정 화면에서 "소속 변경 문의" 탭 시 메일 앱이 열림
- **검증 방법**:
  - 설정 화면에서 "소속 변경 문의" 항목 표시 확인
  - 탭 시 메일 앱 열림 + 수신자/제목 자동 입력 확인
- **예상 소요**: 10분

---

## 단계 10: 이미지 용량 제한

- **만들 파일**: 없음
- **수정할 파일**:
  - `lib/screens/post/post_write_screen.dart` (`_pickImage()` 메서드)
- **할 일**:
  1. `_pickImage()`에서 `picker.pickImage()` 호출 후 파일 크기 검증 추가:
     - `File(picked.path).length()` → `sizeInMb` 계산
     - `AppConstants.maxImageSizeMb` (5MB, constants.dart에 이미 선언) 초과 시 차단
     - SnackBar로 `'이미지 크기는 5MB 이하만 가능합니다'` 안내
  2. 기존 리사이즈 설정 유지 (`maxWidth: 1920`, `imageQuality: 85`)
  3. 검증은 리사이즈 후 수행 (리사이즈 후에도 초과하는 극대 파일만 차단)
- **의존성**: 없음 (독립)
- **완료 기준**: 리사이즈 후 5MB 초과 이미지 선택 시 에러 메시지 + 정상 이미지는 문제없이 첨부
- **검증 방법**:
  - 매우 큰 이미지(10MB+ RAW) 첨부 시도 → 에러 메시지 확인
  - 일반 사진(1~3MB) 첨부 → 정상 동작 확인
- **예상 소요**: 10분

---

## 단계 11: 포그라운드 FCM 알림

- **만들 파일**: 없음
- **수정할 파일**:
  - `pubspec.yaml` (`flutter_local_notifications` 패키지 추가)
  - `lib/services/notification_service.dart` (`_handleForegroundMessage()` 구현)
- **할 일**:
  1. `pubspec.yaml`에 `flutter_local_notifications: ^18.0.0` 추가
  2. `notification_service.dart`의 `initialize()`에 `FlutterLocalNotificationsPlugin` 초기화:
     - Android: `AndroidInitializationSettings('@mipmap/ic_launcher')`
     - iOS: `DarwinInitializationSettings()`
     - 알림 채널: id `gongter_notifications`, name `공터 알림`
  3. `_handleForegroundMessage()` 구현 (현재 debugPrint만 있음):
     - `message.notification`이 있으면 `FlutterLocalNotificationsPlugin.show()` 호출
     - Android: `AndroidNotificationDetails('gongter_notifications', '공터 알림', importance: Importance.high)`
     - iOS: `DarwinNotificationDetails()`
  4. 알림 탭 시 딥링크 처리는 기존 `_handleNotificationTap()`에 위임
- **의존성**: 없음 (독립)
- **완료 기준**: 앱 포그라운드 상태에서 FCM 메시지 수신 시 시스템 알림 배너 표시
- **검증 방법**:
  - Firebase Console에서 테스트 메시지 전송
  - 앱 포그라운드 상태에서 알림 배너 표시 확인
  - 알림 탭 시 해당 화면으로 이동 확인 (data payload 포함 시)
- **예상 소요**: 25분

---

## 단계 12: AdMob 실제 ID 교체 + 네이티브 광고

- **만들 파일**:
  - `lib/widgets/native_ad_widget.dart` (네이티브 광고 위젯)
- **수정할 파일**:
  - `lib/services/ad_service.dart` (실제 ID 교체 + 네이티브 광고 메서드 추가)
  - `lib/screens/home/home_screen.dart` (ListView.builder에 네이티브 광고 삽입)
  - `ios/Runner/Info.plist` (`GADApplicationIdentifier` 실제 값)
  - `android/app/src/main/AndroidManifest.xml` (AdMob App ID 확인)
- **할 일**:
  1. **AdMob 실제 ID 교체**:
     - AdMob 콘솔에서 앱 등록 (iOS + Android)
     - 배너/전면/네이티브 광고 단위 ID 생성
     - `ad_service.dart`의 테스트 ID → 실제 ID 교체
     - `Info.plist` GADApplicationIdentifier 교체
     - `AndroidManifest.xml` AdMob App ID 확인/교체
  2. **네이티브 광고 추가**:
     - `ad_service.dart`에 네이티브 광고 ID 상수 + `createNativeAd()` 팩토리
     - `native_ad_widget.dart` 생성 (카드형 레이아웃, 로드/에러 처리)
     - `home_screen.dart`의 `_buildLocalTab()`/`_buildHotTab()` ListView.builder 수정:
       매 7개 포스트마다 `NativeAdWidget` 삽입
     - 광고 로드 실패 시 빈 공간 없이 포스트만 표시
- **의존성**: 없음 (독립, 단 AdMob 콘솔 작업 필요)
- **완료 기준**: 실제 광고 로드 + 피드에 네이티브 광고가 7개 포스트마다 표시
- **검증 방법**:
  - 테스트 기기 등록 후 릴리즈 빌드에서 배너/전면/네이티브 모두 로드 확인
  - 피드 스크롤 시 네이티브 광고 카드 표시 확인
  - 광고 로드 실패 시 포스트만 표시 확인
- **예상 소요**: 30분 (AdMob 콘솔 작업 별도)

---

## 단계 13: iOS 빌드

- **만들 파일**:
  - `ios/ExportOptions.plist`
- **수정할 파일**:
  - Xcode 프로젝트 설정 (필요 시)
- **할 일**:
  1. Apple App Store Connect에서 앱 생성 (번들 ID: com.gongter.gongter)
  2. `ExportOptions.plist` 생성 (method: app-store-connect)
  3. Provisioning Profile 생성 (App Store Distribution)
  4. `flutter build ios --release --no-codesign` → xcodebuild archive → export
  5. IPA 생성 확인
- **의존성**: 단계 12 (AdMob 실제 ID가 Info.plist에 반영되어야 함)
- **완료 기준**: IPA 파일 생성 성공
- **검증 방법**:
  - `build/ios/ipa/` 디렉토리에 IPA 파일 존재 확인
  - Transporter 앱으로 업로드 테스트
- **예상 소요**: 30분

---

## 단계 14: 출시 전 최종 점검

- **만들 파일**: 없음
- **수정할 파일**: 점검 중 발견된 버그에 따라 결정
- **할 일**: 실기기(iOS + Android)에서 아래 체크리스트 전체 점검

### 14-1. 인증 플로우
- [ ] 온보딩: 3페이지 스와이프, dot 인디케이터, 건너뛰기/시작하기, 재실행 시 미노출
- [ ] 로그인: 이메일/비번 입력, 에러 처리, 비밀번호 재설정, 프로필 미완성 리다이렉트
- [ ] 회원가입 Step0: korea.kr 검증, 비번 6자+일치, 약관 동의, 이용약관/개인정보 링크
- [ ] 회원가입 Step1: OTP 6자리, 잘못된 코드 에러, 재발송
- [ ] 회원가입 Step2: 지자체 드롭다운(세종시 특수 처리), 닉네임 정규식+금칙어
- [ ] ProfileSetupScreen: 미완성 시 강제 리다이렉트 확인

### 14-2. 메인 피드
- [ ] HomeScreen: AppBar(지자체명/검색/설정), 2탭, 태그 필터칩 7개
- [ ] 내 지자체 탭: 필터링, PostCard, 빈 상태, Pull-to-refresh, 페이지네이션, 네이티브 광고(10포스트/1개)
- [ ] 전국 HOT 탭: 인기글(지자체명 포함), 빈 상태, Pull-to-refresh, 페이지네이션, 네이티브 광고
- [ ] FAB 글쓰기 → 복귀 시 새로고침, 하단 배너 광고
- [ ] MainShell: 4탭 네비바, 알림 배지(미읽음 수), 탭 전환 시 갱신

### 14-3. 글 관리
- [ ] PostWriteScreen: 공무원법 리마인더, 태그 6개, 제목 50자/내용 5000자 카운터, 이미지(최대 5장/5MB), 금칙어 검증, 완료 버튼
- [ ] PostDetailScreen: 태그/시간/제목/수정됨/본문/이미지/조회수, Pull-to-refresh, 배너, 뒤로가기 전면 광고
- [ ] 내 글 메뉴: 수정/삭제, 타인 글 메뉴: 신고(5사유)/차단
- [ ] PostEditScreen: 기존값 로드, 태그 변경, 금칙어 검증

### 14-4. 댓글
- [ ] 작성: 하단 입력란, 빈 댓글 무반응, 금칙어, 즉시 갱신
- [ ] 수정: 다이얼로그(기존 내용), 금칙어, "수정됨" 라벨
- [ ] 삭제: 대댓글 있으면 soft delete("삭제된 댓글입니다"), 없으면 물리 삭제
- [ ] 대댓글: 답글 태그 표시, X 해제, 들여쓰기 32px
- [ ] 익명 표시: 글쓴이(코랄 배지)/나/익명N/탈퇴한 사용자

### 14-5. 상호작용
- [ ] 좋아요(글/댓글): 토글, 카운트 즉시 반영, 더블탭 방지
- [ ] 북마크: 토글(코랄색), 더블탭 방지
- [ ] 신고(글/댓글): 5사유, SnackBar
- [ ] 차단: 확인 다이얼로그, RLS+클라이언트 필터

### 14-6. 탐색
- [ ] ExploreScreen 2탭: 지자체(검색 필터/광역→기초→피드), 게시글 검색(RPC)
- [ ] 빈 상태, 차단 유저 필터링, 클리어 버튼

### 14-7. 프로필
- [ ] ProfileScreen: 아바타/닉네임/지자체/인증 배지, 내 글/댓글/북마크 네비게이션
- [ ] 닉네임 변경: 다이얼로그(2자 이상/정규식/금칙어)
- [ ] 하위 화면: Pull-to-refresh, 빈 상태

### 14-8. 알림
- [ ] NotificationScreen: 목록(미읽음 하이라이트), 아이콘(댓글/좋아요/신고/시스템), timeago
- [ ] 탭 → 읽음+상세 이동, 빈 상태, Pull-to-refresh
- [ ] FCM: 포그라운드 로컬 알림, 백그라운드 시스템 알림, 탭 시 이동

### 14-9. 설정
- [ ] 법적 고지: 공무원법/이용약관/개인정보(외부 링크)
- [ ] 문의: 고객 문의(메일 앱)
- [ ] 차단 목록: 목록+해제+빈 상태
- [ ] 소속 변경 문의: 다이얼로그+메일 템플릿
- [ ] 로그아웃: FCM cleanup+로그인 화면
- [ ] 계정 삭제: 확인 다이얼로그+익명화+"탈퇴한 사용자"
- [ ] 버전 표시 v1.0.0

### 14-10. 광고
- [ ] 배너: 홈/글 상세 하단, 로드 실패 처리
- [ ] 전면: 글 상세 뒤로가기, 3회/일, 3분 간격, preload
- [ ] 네이티브: 10포스트/1개, 실패 시 빈 공간 없음

### 14-11. 관리자
- [ ] 관리자 섹션 비관리자 미노출
- [ ] 공지 발송: 제목/내용 다이얼로그, 빈 제목 무반응
- [ ] 지자체 변경: 드롭다운+변경하기

### 14-12. 엣지 케이스
- [ ] 네트워크 오류: 비행기 모드에서 피드/글 작성/댓글
- [ ] 빈 상태: 홈/HOT/검색 전/검색 0건/알림/내 글/댓글/북마크/차단/지자체 피드
- [ ] 긴 텍스트: 제목 50자/내용 5000자/닉네임 10자/이미지 5장/댓글 100+
- [ ] 동시성: 좋아요/북마크/완료 더블탭 방지
- [ ] 라우팅: 로그인 상태에서 /login, 비로그인에서 홈, 미완성 프로필, 없는 게시글

### 14-13. iOS/Android 공통
- [ ] 권한: 갤러리/카메라/ATT(iOS)/알림(Android 13+)
- [ ] SafeArea(iOS), 상태바 겹침(Android), 키보드 push/dismiss
- [ ] 앱 아이콘, 스플래시, 앱 이름 "공터", flutter analyze

- **의존성**: 단계 13 (iOS 빌드 완료 후)
- **완료 기준**: 체크리스트 전항목 통과 + 발견된 버그 모두 수정
- **검증 방법**: 실기기(iOS + Android)에서 전체 체크리스트 1회 이상 통과
- **예상 소요**: 2~3시간

---

## 단계 15: 출시 준비

- **만들 파일**: 없음 (스크린샷/메타데이터는 별도 작업)
- **수정할 파일**: 없음

### 15-1. 스크린샷 촬영 (6~8장)
- 해상도: 6.7인치(1290x2796) 기준 + 리사이즈
- 시나리오: (1)온보딩 1페이지 (2)홈 내 지자체 탭 (3)홈 전국 HOT (4)글쓰기 (5)글 상세+댓글 (6)탐색 지자체 (7)프로필 (8)알림
- 상태바 정리: `xcrun simctl status_bar`
- 실명/개인정보 미포함 확인

### 15-2. App Store 메타데이터
- 앱 이름/부제목/번들 ID/카테고리(소셜 네트워킹)
- 설명(4000자), 키워드(100자)
- Age Rating: UGC=YES, 도박=NO → 17+
- Review Notes: 테스트 계정(master@gongter.app / master123!) + UGC 요건 충족 안내
- Privacy/Terms/Support URL

### 15-3. Google Play 메타데이터
- 앱 이름/짧은 설명(80자)/긴 설명
- 아이콘 512x512 / 그래픽 이미지 1024x500
- 데이터 안전 섹션 (이메일/닉네임/지자체, HTTPS, 삭제 가능, AdMob 공유)
- IARC 설문 → 12세 이상
- 타겟 오디언스: 18세 이상, 아동 대상 아님

### 15-4. 제출 절차
- **App Store**: IPA 업로드 → ASC 빌드 확인 → 버전 생성 → 스크린샷/메타데이터 → 심사 제출
- **Google Play**: AAB 빌드 → 비공개 테스트 → 도플리 14일(12명, 2~4회 업데이트) → 프로덕션 전환

- **의존성**: 단계 14 (최종 점검 통과 후)
- **완료 기준**: 양쪽 스토어에 심사 제출 완료
- **검증 방법**:
  - App Store Connect에서 "심사 대기" 상태 확인
  - Google Play Console에서 비공개 테스트 트랙에 업로드 확인
- **예상 소요**: 1~2시간 (스크린샷 작업 포함)

---

## 단계 의존성 맵

```
단계 1~12: 완료됨 ✅

단계 13 (iOS 빌드) ──→ 단계 14 (최종 점검) ──→ 단계 15 (출시 준비)
```

## 병렬 실행 가능 그룹

- **그룹 A** (독립, 동시 가능): 단계 7, 8, 9, 10, 11 — ✅ 완료
- **그룹 B** (순차): 단계 12 → 단계 13 → 단계 14 → 단계 15

단계 13(iOS 빌드) 완료 후 단계 14(최종 점검)를 진행하고, 점검 통과 후 단계 15(출시 준비)로 진행합니다.

---

## v2 (출시 후) -- 이번 계획에서 제외

| 항목 | 사유 |
|---|---|
| Riverpod 마이그레이션 | 현재 StatefulWidget 동작 정상, 리팩토링 리스크 대비 효과 낮음 |
| 기관/부서 리뷰 | PRD Phase 4 (출시 후) |
| 직렬별/광역 게시판 | PRD Phase 4 |
| 쪽지 기능 | PRD Phase 4 |
| 글 수정 시 이미지 추가/삭제 | v2 개선 |
| 인사이동 전체 UI (재인증 플로우) | 현재는 이메일 문의로 대체, 사용자 증가 시 셀프서비스 전환 |
