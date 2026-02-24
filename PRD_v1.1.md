# 지방공무원 커뮤니티 앱 PRD v1.1

> **앱 이름**: 공터 (Gongter)
> **컨셉**: 지자체별 통합 피드 중심의 가벼운 공무원 익명 커뮤니티
> **타겟**: 전국 약 38만 지방공무원
> **수익**: 광고 (AdMob) - 출시 첫날부터
> **스택**: Flutter + Supabase + AdMob
> **출시**: iOS + Android 동시
> **작성일**: 2026.02.24

---

## 1. 프로젝트 개요

### 1.1 핵심 가설

에브리타임(대학생), 블라인드(직장인)처럼 **지방공무원 전용 익명 커뮤니티**는 빈 시장이다.

- 전국 243개 기초자치단체 + 17개 광역자치단체
- 약 38만 지방공무원
- 기존 경쟁: 공무원 전용 커뮤니티 앱 **없음**

### 1.2 앱 구조 (가벼운 버전)

```
243개 지자체 × 통합 피드 1개 = 243개 피드
+ 전국 HOT 피드 (인기글 자동 수집)
```

- 각 지자체마다 **1개 통합 피드** (태그로 자유/질문/정보/유머 구분)
- 전국 게시판, 광역 게시판, 직렬 게시판 → **MVP에서 제외**
- 기관/부서 리뷰 → **v2에서 추가**

### 1.3 앱 이름: 공터

- **의미**: 공무원의 "공(公)" + "터(자리, 공간)" = 공무원들의 자유로운 공간
- **부제**: "공터 — 지방공무원 익명 커뮤니티"
- **서브타이틀**: "38만 지방공무원의 익명 마당" (앱스토어용)

---

## 2. 게시판 구조

### 2.1 지자체 통합 피드

각 지자체마다 **하나의 피드**. 글 작성 시 태그를 선택하고, 사용자는 태그별 필터링 가능.

**태그 종류**:
| 태그 | 설명 |
|---|---|
| 자유 | 일상, 잡담, 아무 얘기 |
| 질문 | 업무, 제도, 이직 관련 질문 |
| 정보 | 인사, 복지, 시험 정보 공유 |
| 유머 | 웃긴 얘기, 공무원 밈 |

### 2.2 전국 HOT 피드

- 전 지자체 글 중 **인기글 자동 수집**
- HOT 점수 알고리즘:
  ```
  hot_score = (likes × 3 + comments × 2 + views × 0.1) / (age_hours + 2)^1.5
  ```
- 5분마다 상위 200개 갱신 (materialized view)

### 2.3 홈 화면 구성

```
[내 지자체] [전국 HOT]  ← 탭 전환
```

- **내 지자체 탭**: 소속 지자체 피드 (최신순)
- **전국 HOT 탭**: 전국 인기글 (HOT 점수순)
- 다른 지자체 피드도 **탐색(구경)** 가능 (읽기 + 댓글 OK, 글쓰기만 내 지자체)

---

## 3. 핵심 기능

### 3.1 게시글

- **글쓰기**: 소속 지자체 피드에만 가능
- **열람**: 전국 모든 지자체 피드 열람 가능
- **익명**: 전체 익명 (작성자 정보 비공개)
- **수정**: 허용. 수정된 글에 "수정됨" 뱃지 표시
- **삭제**: 작성자가 언제든 삭제 가능 (댓글 있어도)
- **태그**: 자유/질문/정보/유머 중 1개 선택
- **이미지**: 최대 5장, 장당 5MB 이하, JPG/PNG/WebP만
- **제목**: 최대 50자 / **본문**: 최대 5,000자

### 3.2 댓글

- **범위**: 전국 어디든 댓글 가능 (다른 지자체 글에도)
- **익명**: 블라인드 방식 - 모두 "익명" (번호 없음)
- **대댓글**: 1depth까지
- **글쓴이 뱃지**: 원글 작성자가 댓글 달면 "글쓴이" 표시
- **삭제**: 대댓글이 있으면 "삭제된 댓글입니다"로 표시 (대댓글 유지). 대댓글 없으면 물리 삭제
- **수정**: 허용. "수정됨" 표시

### 3.3 좋아요 / 북마크

- 좋아요: 게시글 + 댓글
- 북마크: 게시글만
- 중복 방지

### 3.4 차단

- **양방향 차단**: A가 B를 차단하면 서로 글/댓글이 안 보임
- RLS 레벨에서 필터링 (클라이언트 우회 불가)

### 3.5 신고 시스템 (UGC 필수)

- **신고 사유**: 욕설/비방, 개인정보노출, 스팸/광고, 음란, 기타
- **중복 신고 방지**: 같은 대상 1인 1회
- **5건 누적 → 자동 블라인드**
- **관리**: MVP는 Supabase Dashboard에서 SQL로 처리 (admin role)
- **Apple 1.2 / Google UGC 필수 요건**:
  - 욕설 필터링 (금칙어 테이블)
  - 신고 기능
  - 차단 기능 (양방향)
  - 고객 문의 연락처 (설정 화면)
  - 게시 전 혐오표현 사전 필터링 (Google)

### 3.6 검색

- PostgreSQL `pg_trgm` + GIN 인덱스 (한국어 지원)
- 내 지자체 / 전국 범위 선택

### 3.7 닉네임

- **용도**: 마이페이지 내부 식별용만 (글/댓글에 미노출)
- **중복 허용** (UNIQUE 불필요)
- 글자수: 2~10자, 한글/영문/숫자

### 3.8 탈퇴

- **글/댓글**: 삭제하지 않고 "탈퇴한 사용자"로 익명화 (블라인드 방식)
- author_id를 시스템 UUID로 변경, 내용은 유지
- 프로필/인증 정보만 삭제

### 3.9 Cold Start 대응

- **내 지자체에 글이 없으면**: 전국 최신글을 기본으로 보여줌
- **"첫 글을 작성해보세요"** CTA 버튼 표시
- 전국 HOT도 비어있는 초기에는 전국 최신글로 대체

### 3.6 법적 공지 (앱 내)

> 공무원들은 규정에 익숙하므로 앱 내 공지로 충분

**온보딩 시 공지** + **글쓰기 화면 상단 고정 안내**:

```
[공무원법 주의사항]
- 직무상 비밀 누설 금지 (제60조)
- 품위유지 의무 (제63조)
- 정치 중립 의무 (제65조)
- 본 앱의 게시글은 개인 의견이며,
  법적 책임은 작성자 본인에게 있습니다.
```

- 회원가입 시 동의 체크
- 글쓰기 화면에 간략 리마인더
- 설정 > 이용약관에 전문 포함

---

## 4. 인증 시스템

### 4.1 인증 방식 (2가지 동등)

> **핵심 이슈**: go.kr 메일서버가 외부 SMTP를 차단할 수 있음.
> 개발자가 go.kr 이메일이 없어서 사전 테스트가 어려움.
> → 재직증명서 인증을 "보조"가 아닌 **동등한 메인 옵션**으로 격상

**인증 선택 화면**:
```
공터 인증 방법을 선택하세요:

[1] 공무원 이메일 인증 (*.go.kr)
    → 이메일로 인증코드 발송

[2] 재직증명서 인증
    → 재직증명서 사진 촬영/업로드
    → 1~2일 내 승인
```

#### 방법 1: *.go.kr 이메일 인증

1. `*.go.kr` 이메일 입력
2. 인증 코드 발송 (6자리 OTP, 5분 유효)
3. 이메일 도메인 → 소속 지자체 자동 매칭
4. 인증 완료

**기술 주의사항**:
- 커스텀 SMTP 필수 (SPF/DKIM/DMARC 설정하여 스팸 방지)
- OTP 방식 사용 (Magic Link는 메일 보안 게이트웨이가 자동 클릭할 수 있음)
- 인증 코드 재발송: 60초 쿨다운, 일 최대 5회
- 도메인 제한: auth.users INSERT trigger에서 go.kr 검증
- **MVP 개발 후 실제 go.kr 계정으로 반드시 테스트**
- **테스트 실패 시**: 재직증명서 인증을 단독 메인으로 전환

**도메인 매핑**:
- `@namyangju.go.kr` → 경기도 남양주시
- `@gwangmyeong.go.kr` → 경기도 광명시
- `@inje.go.kr` → 강원특별자치도 인제군
- 매핑 실패 시 → 수동으로 지자체 선택 + 재직증명서 인증으로 안내

#### 방법 2: 재직증명서 인증

1. 재직증명서 사진 촬영/업로드
2. 소속 지자체 수동 선택
3. 개인정보(주민번호 등) 모자이크 가이드 표시
4. 운영자 수동 심사 (1~2일)
5. 승인/거절 결과 앱 알림
6. **심사 완료 후 증명서 이미지 자동 삭제** (개인정보 보호)

#### Apple 심사용 테스트 계정

- 심사관은 go.kr 이메일이 없으므로 테스트 불가
- **해결**: 테스트 모드 플래그 또는 사전 인증된 테스트 계정 제공
- Review Notes에 테스트 계정 정보 명시

### 4.2 인사이동(전보) 처리

- 새 소속 지자체 이메일로 재인증 또는 재직증명서 재제출
- 이전 지자체 게시글은 유지 (작성 당시 지자체에 귀속)
- `transfer_history` 테이블로 이력 관리

---

## 5. 법적 검토

### 5.1 확인된 사실

| 항목 | 결론 |
|---|---|
| 공무원법 위반 | **개인** 처벌. 플랫폼 운영자와 무관 |
| 정보통신망법 제44조의2 | 30일 내 임시조치 시 **플랫폼 면책** |
| "위반 조장 플랫폼" 지정 | 그런 법적 메커니즘 **없음** |
| 블라인드/DC인사이드 선례 | 공무원 콘텐츠 호스팅 중, 문제 없음 |
| 부가통신사업 신고 | 자본금 1억 미만 **면제** |

### 5.2 필수 구현

1. 신고/차단 시스템
2. 임시조치 (30일 내)
3. 이용약관 (공무원법 위반 콘텐츠 금지 명시)
4. 개인정보처리방침 (Privacy Policy)
5. 앱 내 법적 공지 (3.6절)

### 5.3 앱스토어 심사

| 가이드라인 | 대응 |
|---|---|
| Apple 1.2 (UGC) | 필터/신고/차단/연락처 구현 |
| Google UGC | + 혐오표현 사전 필터링 |
| 4.3(a) Spam | 해당 없음 (니치 커뮤니티) |

---

## 6. DB 스키마 (Supabase / PostgreSQL)

### 6.1 테이블

```sql
-- =============================================
-- 지자체 (243 기초 + 17 광역 = 260개)
-- =============================================
CREATE TABLE municipalities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,                -- '남양주시'
  full_name TEXT NOT NULL,           -- '경기도 남양주시'
  admin_code VARCHAR(5) NOT NULL UNIQUE,
  level SMALLINT NOT NULL,           -- 1=광역, 2=기초
  parent_id UUID REFERENCES municipalities(id),
  email_domain TEXT,                 -- 'namyangju.go.kr'
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- 사용자 프로필
-- =============================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  municipality_id UUID REFERENCES municipalities(id),
  nickname TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_method TEXT,          -- 'email' / 'document'
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- 게시글 (지자체 통합 피드)
-- =============================================
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id),
  municipality_id UUID NOT NULL REFERENCES municipalities(id),
  tag TEXT NOT NULL DEFAULT 'free',  -- 'free'/'question'/'info'/'humor'
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  image_urls TEXT[],
  view_count INT DEFAULT 0,
  like_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  hot_score FLOAT DEFAULT 0,
  is_blinded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- 댓글
-- =============================================
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id),
  parent_id UUID REFERENCES comments(id),  -- 대댓글 1depth
  content TEXT NOT NULL,
  like_count INT DEFAULT 0,
  is_blinded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- 좋아요 (다형)
-- =============================================
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  target_type TEXT NOT NULL,         -- 'post' / 'comment'
  target_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, target_type, target_id)
);

-- =============================================
-- 신고
-- =============================================
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id),
  target_type TEXT NOT NULL,         -- 'post' / 'comment' / 'user'
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,              -- 'abuse'/'privacy'/'spam'/'obscene'/'other'
  detail TEXT,
  status TEXT DEFAULT 'pending',     -- pending/reviewing/resolved/dismissed
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- 북마크
-- =============================================
CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, post_id)
);

-- =============================================
-- 사용자 차단
-- =============================================
CREATE TABLE blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES profiles(id),
  blocked_id UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(blocker_id, blocked_id)
);

-- =============================================
-- 인사이동 이력
-- =============================================
CREATE TABLE transfer_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  from_municipality_id UUID REFERENCES municipalities(id),
  to_municipality_id UUID NOT NULL REFERENCES municipalities(id),
  transferred_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- 알림
-- =============================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  type TEXT NOT NULL,                -- 'comment'/'like'/'report_result'
  title TEXT NOT NULL,
  body TEXT,
  target_type TEXT,                  -- 'post'/'comment'
  target_id UUID,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 6.2 인덱스

```sql
-- 피드 조회 (지자체 + 최신순)
CREATE INDEX idx_posts_muni_created ON posts(municipality_id, created_at DESC)
  WHERE is_blinded = FALSE;

-- HOT 피드
CREATE INDEX idx_posts_hot ON posts(hot_score DESC)
  WHERE is_blinded = FALSE;

-- 태그 필터
CREATE INDEX idx_posts_muni_tag ON posts(municipality_id, tag, created_at DESC)
  WHERE is_blinded = FALSE;

-- 댓글
CREATE INDEX idx_comments_post ON comments(post_id, created_at ASC);

-- 한국어 검색 (pg_trgm)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_posts_title_trgm ON posts USING GIN (title gin_trgm_ops);
CREATE INDEX idx_posts_content_trgm ON posts USING GIN (content gin_trgm_ops);

-- 좋아요 / 신고
CREATE INDEX idx_likes_target ON likes(target_type, target_id);
CREATE INDEX idx_reports_target ON reports(target_type, target_id, status);

-- 알림
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at DESC);

-- 차단
CREATE INDEX idx_blocks_blocker ON blocks(blocker_id);
```

### 6.3 RLS

```sql
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 게시글: 전국 열람, 글쓰기는 내 지자체만
CREATE POLICY "posts_select" ON posts FOR SELECT
  TO authenticated USING (TRUE);

CREATE POLICY "posts_insert" ON posts FOR INSERT
  TO authenticated WITH CHECK (
    municipality_id = (SELECT municipality_id FROM profiles WHERE id = auth.uid())
  );

CREATE POLICY "posts_update" ON posts FOR UPDATE
  TO authenticated USING (author_id = auth.uid());

CREATE POLICY "posts_delete" ON posts FOR DELETE
  TO authenticated USING (author_id = auth.uid());

-- 댓글: 전국 어디든 작성 가능
CREATE POLICY "comments_select" ON comments FOR SELECT
  TO authenticated USING (TRUE);

CREATE POLICY "comments_insert" ON comments FOR INSERT
  TO authenticated WITH CHECK (TRUE);

CREATE POLICY "comments_delete" ON comments FOR DELETE
  TO authenticated USING (author_id = auth.uid());

-- 좋아요/북마크/차단: 본인만
CREATE POLICY "likes_all" ON likes FOR ALL
  TO authenticated USING (user_id = auth.uid());

CREATE POLICY "bookmarks_all" ON bookmarks FOR ALL
  TO authenticated USING (user_id = auth.uid());

CREATE POLICY "blocks_all" ON blocks FOR ALL
  TO authenticated USING (blocker_id = auth.uid());

-- 알림: 본인만
CREATE POLICY "notifications_all" ON notifications FOR ALL
  TO authenticated USING (user_id = auth.uid());
```

### 6.4 트리거 & 함수

```sql
-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_posts_updated BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER tr_comments_updated BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- 좋아요 수 동기화
CREATE OR REPLACE FUNCTION sync_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.target_type = 'post' THEN
      UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.target_id;
    ELSIF NEW.target_type = 'comment' THEN
      UPDATE comments SET like_count = like_count + 1 WHERE id = NEW.target_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.target_type = 'post' THEN
      UPDATE posts SET like_count = like_count - 1 WHERE id = OLD.target_id;
    ELSIF OLD.target_type = 'comment' THEN
      UPDATE comments SET like_count = like_count - 1 WHERE id = OLD.target_id;
    END IF;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_likes_sync AFTER INSERT OR DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION sync_like_count();

-- 댓글 수 동기화
CREATE OR REPLACE FUNCTION sync_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_comments_count AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION sync_comment_count();

-- HOT 점수 계산
CREATE OR REPLACE FUNCTION calculate_hot_score(
  p_likes INT, p_comments INT, p_views INT, p_created_at TIMESTAMPTZ
) RETURNS FLOAT AS $$
BEGIN
  RETURN (p_likes * 3.0 + p_comments * 2.0 + p_views * 0.1)
    / POWER(EXTRACT(EPOCH FROM (now() - p_created_at)) / 3600 + 2, 1.5);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- HOT 점수 일괄 갱신 (pg_cron 5분마다)
CREATE OR REPLACE FUNCTION refresh_hot_scores()
RETURNS VOID AS $$
BEGIN
  UPDATE posts SET hot_score = calculate_hot_score(like_count, comment_count, view_count, created_at)
  WHERE created_at > now() - INTERVAL '7 days' AND is_blinded = FALSE;
END;
$$ LANGUAGE plpgsql;

-- HOT 200 Materialized View
CREATE MATERIALIZED VIEW mv_hot_posts AS
  SELECT id, title, municipality_id, tag, hot_score,
         like_count, comment_count, view_count, created_at
  FROM posts
  WHERE is_blinded = FALSE AND created_at > now() - INTERVAL '7 days'
  ORDER BY hot_score DESC LIMIT 200;

CREATE UNIQUE INDEX idx_mv_hot_posts ON mv_hot_posts(id);

-- 신고 5건 자동 블라인드
CREATE OR REPLACE FUNCTION auto_blind_on_report()
RETURNS TRIGGER AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM reports
  WHERE target_type = NEW.target_type AND target_id = NEW.target_id AND status != 'dismissed';

  IF v_count >= 5 THEN
    IF NEW.target_type = 'post' THEN
      UPDATE posts SET is_blinded = TRUE WHERE id = NEW.target_id;
    ELSIF NEW.target_type = 'comment' THEN
      UPDATE comments SET is_blinded = TRUE WHERE id = NEW.target_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_auto_blind AFTER INSERT ON reports
  FOR EACH ROW EXECUTE FUNCTION auto_blind_on_report();

-- 검색
CREATE OR REPLACE FUNCTION search_posts(
  p_query TEXT,
  p_municipality_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
) RETURNS SETOF posts AS $$
BEGIN
  RETURN QUERY
    SELECT * FROM posts
    WHERE is_blinded = FALSE
      AND (p_municipality_id IS NULL OR municipality_id = p_municipality_id)
      AND (title ILIKE '%' || p_query || '%' OR content ILIKE '%' || p_query || '%')
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- 계정 삭제 RPC
CREATE OR REPLACE FUNCTION delete_my_account()
RETURNS VOID AS $$
BEGIN
  DELETE FROM notifications WHERE user_id = auth.uid();
  DELETE FROM blocks WHERE blocker_id = auth.uid() OR blocked_id = auth.uid();
  DELETE FROM bookmarks WHERE user_id = auth.uid();
  DELETE FROM likes WHERE user_id = auth.uid();
  DELETE FROM comments WHERE author_id = auth.uid();
  DELETE FROM posts WHERE author_id = auth.uid();
  DELETE FROM transfer_history WHERE user_id = auth.uid();
  DELETE FROM profiles WHERE id = auth.uid();
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 6.5 Storage

```
Supabase Storage: post-images 버킷
폴더: {user_id}/{filename}
RLS: 본인 폴더만 업로드, 전체 읽기 허용
```

---

## 7. 광고 수익

### 7.1 전략: 출시 첫날부터 배너 광고

| Phase | 시점 | 광고 |
|---|---|---|
| **런칭** | Day 1 | **배너 광고** (하단 고정) |
| 성장기 | MAU 3,000+ | + 네이티브 (피드 5번째마다) |
| 안정기 | MAU 10,000+ | + 전면 (화면 전환 시, 최대 3회/일) |
| 확장기 | MAU 30,000+ | + B2B 직접 광고 영업 |

### 7.2 eCPM 기준

| 형식 | eCPM (보수적) |
|---|---|
| 배너 | $0.40 |
| 네이티브 | $1.20 |
| 전면 | $4.00 |

### 7.3 수익 전망

| MAU | 월 수익 (추정) | 비고 |
|---|---|---|
| 1,000 | ~30만원 | 배너만 |
| 5,000 | ~250만원 | 배너+네이티브 |
| 30,000 | ~1,500만원 | 전 형식 |

---

## 8. 화면 구성 (IA)

### 8.1 메인 탭 (4탭, 가벼운 구조)

```
[홈] [탐색] [알림] [마이]
```

### 8.2 화면 목록

| 화면 | 설명 |
|---|---|
| **스플래시** | 로고 + 로딩 |
| **온보딩** | 앱 소개 + 공무원법 주의사항 공지 + 이용약관 동의 |
| **회원가입** | *.go.kr 이메일 입력 → 인증코드 확인 |
| **로그인** | 이메일 + 비밀번호 |
| **홈** | [내 지자체 / 전국 HOT] 탭 전환 + 배너 광고 |
| **글 목록** | 태그 필터 (전체/자유/질문/정보/유머) |
| **글 상세** | 본문 + 댓글 + 좋아요/북마크/신고 + 배너 |
| **글쓰기** | 태그 선택 + 제목/본문/이미지 + 공무원법 리마인더 |
| **탐색** | 지자체 검색/목록 → 다른 지자체 피드 구경 |
| **알림** | 댓글/좋아요/신고결과 |
| **마이** | 내 글/댓글/북마크 |
| **설정** | 알림/다크모드/계정삭제/이용약관/개인정보처리방침 |
| **신고** | 사유 선택 + 상세 입력 |
| **프로필 수정** | 닉네임 변경 |

### 8.3 디자인 테마

- **컬러 팔레트**:
  - Primary: `#2E7D32` (딥 그린)
  - Secondary: `#81C784` (라이트 그린)
  - Surface: `#F5F9F5` (민트 화이트)
  - Accent: `#FFC107` (앰버)
  - Error: `#D32F2F`
  - Text Primary: `#212121`
  - Text Secondary: `#757575`
- **분위기**: "열린 마당" - 신선하고 편안한 느낌
- **아이콘**: 나무/마당 모티브
- **다크모드**: 지원 (설정에서 전환)
  - Surface Dark: `#121212`
  - Primary Dark: `#66BB6A`
- **Material 3**: `useMaterial3: true`

---

## 9. 기술 스택

| 영역 | 기술 |
|---|---|
| 프레임워크 | Flutter (iOS + Android) |
| 백엔드 | Supabase (PostgreSQL + Auth + Storage) |
| 인증 | Supabase Auth (이메일) |
| 상태관리 | Riverpod |
| 로컬저장 | SharedPreferences |
| 광고 | AdMob (google_mobile_ads) |
| 푸시알림 | FCM |
| 이미지 | Supabase Storage + cached_network_image |
| 검색 | PostgreSQL pg_trgm |

---

## 10. 개발 로드맵

### Phase 1: MVP (3주)
- [ ] Supabase 프로젝트 + DB 스키마 배포
- [ ] 지자체 데이터 시딩 (243+17개, 이메일 도메인 매핑)
- [ ] 회원가입/로그인 (*.go.kr 이메일 인증)
- [ ] 홈 (내 지자체 피드 + 전국 HOT)
- [ ] 태그 필터링
- [ ] 게시글 CRUD (익명)
- [ ] 댓글 (블라인드 방식)
- [ ] 좋아요/북마크
- [ ] 신고/차단 시스템
- [ ] 법적 공지 (온보딩 + 글쓰기)
- [ ] 배너 광고 (AdMob)

### Phase 2: 안정화 (1~2주)
- [ ] 탐색 (다른 지자체 구경)
- [ ] 검색
- [ ] 푸시 알림 (FCM)
- [ ] 이미지 업로드
- [ ] 계정 삭제
- [ ] QA + 버그 수정

### Phase 3: 출시 (1주)
- [ ] 앱스토어 메타데이터 + 스크린샷
- [ ] Privacy Policy 페이지
- [ ] iOS App Store 제출
- [ ] Google Play 제출 (도플리)

### Phase 4: v2 (출시 후)
- [ ] 기관/부서 리뷰 (킬러 피처)
- [ ] 직렬별 게시판 (행정/세무/토목)
- [ ] 광역 게시판
- [ ] 네이티브/전면 광고 추가
- [ ] 쪽지 기능

---

## 11. 확정 사항

| 항목 | 결정 |
|---|---|
| 앱 이름 | **공터** (Gongter) |
| 게시판 구조 | 지자체당 통합 피드 1개 + 전국 HOT |
| 태그 | 자유/질문/정보/유머 |
| 댓글 범위 | 전국 어디든 |
| 익명 방식 | 블라인드 (모두 "익명") |
| 닉네임 | 마이페이지에서만 사용, 글/댓글 미노출, 중복 허용 |
| 게시글 수정 | 허용 + "수정됨" 뱃지 표시 |
| 게시글 삭제 | 가능 (댓글 있어도) |
| 댓글 삭제 | 대댓글 있으면 "삭제된 댓글입니다" 표시, 없으면 물리 삭제 |
| 차단 방식 | 양방향 (서로 글/댓글 안 보임) |
| 탈퇴 | 글/댓글 익명화("탈퇴한 사용자"), 프로필만 삭제 |
| 타 지자체 열람 | 가능 (읽기+댓글), 글쓰기만 내 지자체 |
| 전국 HOT | 포함 |
| Cold Start | 내 지자체 비어있으면 전국 최신글 + "첫 글 작성" CTA |
| 인증 | go.kr 이메일 + 재직증명서 (동등한 2가지 옵션) |
| 기관 리뷰 | v2에서 추가 |
| 직렬/광역 게시판 | v2에서 추가 |
| 법적 공지 | 온보딩 + 글쓰기 화면에 공무원법 안내 |
| 광고 | 출시 첫날부터 배너 광고 |
| 관리자 | MVP는 Supabase Dashboard + admin role |
| 출시 | iOS + Android 동시 |

---

## 부록 A: 행정표준코드 매핑 예시

| admin_code | level | full_name | email_domain |
|---|---|---|---|
| 11 | 1 | 서울특별시 | seoul.go.kr |
| 26 | 1 | 부산광역시 | busan.go.kr |
| 41 | 1 | 경기도 | gg.go.kr |
| 11110 | 2 | 서울특별시 종로구 | jongno.go.kr |
| 41590 | 2 | 경기도 남양주시 | namyangju.go.kr |
| 41210 | 2 | 경기도 광명시 | gm.go.kr |
| 42720 | 2 | 강원특별자치도 인제군 | inje.go.kr |

→ 행정안전부 행정표준코드관리시스템에서 전체 수집

## 부록 B: 금지 콘텐츠 (이용약관)

1. 직무상 비밀 누설 (공무원법 제60조)
2. 특정인 개인정보 노출
3. 욕설/비방/혐오 표현
4. 음란물
5. 스팸/광고
6. 정치적 편향 발언 (정치 중립 의무)
7. 허위사실 유포
