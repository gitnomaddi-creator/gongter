-- =============================================
-- 공터 (Gongter) - 지방공무원 익명 커뮤니티
-- 초기 DB 스키마 v1.1
-- 작성일: 2026-02-24
-- =============================================

-- =============================================
-- 0. Extensions
-- pg_trgm: 한국어 유사 검색 (trigram)
-- pg_cron: HOT 점수 주기적 갱신
-- =============================================
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- =============================================
-- 1. TABLES
-- =============================================

-- ---------------------------------------------
-- 1.1 지자체 (243 기초 + 17 광역 = 260개)
-- 행안부 행정표준코드 기반. 이메일 도메인 매핑 포함.
-- ---------------------------------------------
CREATE TABLE municipalities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,                          -- '남양주시'
  full_name TEXT NOT NULL,                     -- '경기도 남양주시'
  admin_code VARCHAR(5) NOT NULL UNIQUE,       -- 행정표준코드 (11, 41590 등)
  level SMALLINT NOT NULL CHECK (level IN (1, 2)),  -- 1=광역, 2=기초
  parent_id UUID REFERENCES municipalities(id),
  email_domain TEXT,                           -- 'namyangju.go.kr'
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE municipalities IS '전국 지방자치단체 목록. 광역(17) + 기초(243) = 260개';

-- ---------------------------------------------
-- 1.2 사용자 프로필
-- auth.users와 1:1. 탈퇴 시 CASCADE로 같이 삭제되지만,
-- 탈퇴 전에 delete_my_account()에서 posts/comments를 익명화 처리.
-- ---------------------------------------------
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  municipality_id UUID REFERENCES municipalities(id),
  nickname TEXT,                                -- 마이페이지 전용, 중복 허용
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verification_method TEXT CHECK (verification_method IN ('email', 'document')),
  verified_email TEXT,                          -- 인증에 사용된 go.kr 이메일 캐싱
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE profiles IS '사용자 프로필. status로 계정 상태 관리, role로 관리자 구분';
COMMENT ON COLUMN profiles.verified_email IS '인증에 사용된 *.go.kr 이메일. 재인증 시 갱신';
COMMENT ON COLUMN profiles.status IS 'active=정상, suspended=정지, deleted=탈퇴처리됨';

-- ---------------------------------------------
-- 1.3 이메일 인증 (OTP)
-- go.kr 이메일 인증 시 6자리 OTP 코드 저장.
-- 5분 유효, 일 최대 5회, 60초 쿨다운은 클라이언트 + Edge Function에서 처리.
-- ---------------------------------------------
CREATE TABLE email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,                          -- 'user@namyangju.go.kr'
  code VARCHAR(6) NOT NULL,                     -- 6자리 OTP
  expires_at TIMESTAMPTZ NOT NULL,              -- 생성 시점 + 5분
  verified BOOLEAN NOT NULL DEFAULT FALSE,      -- 인증 완료 여부
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE email_verifications IS 'go.kr 이메일 OTP 인증 코드. 5분 유효';

-- expired row 자동 조회용 인덱스
CREATE INDEX idx_email_verifications_lookup
  ON email_verifications(email, code)
  WHERE verified = FALSE;

-- ---------------------------------------------
-- 1.4 재직증명서 인증 심사
-- 운영자 수동 심사. 승인 후 이미지 자동 삭제 (Storage cleanup 별도).
-- ---------------------------------------------
CREATE TABLE document_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,                       -- Supabase Storage URL
  municipality_id UUID NOT NULL REFERENCES municipalities(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewer_note TEXT,                           -- 거절 사유 등
  reviewed_at TIMESTAMPTZ,                      -- 심사 완료 시점
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE document_verifications IS '재직증명서 인증 심사. 승인 후 file_url의 이미지는 Storage에서 삭제 필요';

CREATE INDEX idx_document_verifications_pending
  ON document_verifications(status, created_at ASC)
  WHERE status = 'pending';

-- ---------------------------------------------
-- 1.5 금칙어 목록
-- 게시 전 필터링 (Apple 1.2 + Google UGC 요건).
-- category로 욕설/비방/음란/개인정보 등 분류.
-- ---------------------------------------------
CREATE TABLE banned_words (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  word TEXT NOT NULL UNIQUE,                    -- 금칙어
  category TEXT NOT NULL DEFAULT 'abuse'        -- 'abuse'/'obscene'/'privacy'/'spam'/'other'
    CHECK (category IN ('abuse', 'obscene', 'privacy', 'spam', 'other')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE banned_words IS '금칙어 목록. 게시/댓글 작성 시 사전 필터링에 사용';

CREATE INDEX idx_banned_words_word_trgm
  ON banned_words USING GIN (word gin_trgm_ops);

-- ---------------------------------------------
-- 1.6 게시글 (지자체 통합 피드)
-- author_id는 nullable: 탈퇴 시 NULL로 익명화.
-- is_deleted=TRUE면 soft delete (본문은 유지하되 클라이언트에서 비노출).
-- ---------------------------------------------
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- 탈퇴 시 NULL (익명화)
  municipality_id UUID NOT NULL REFERENCES municipalities(id),
  tag TEXT NOT NULL DEFAULT 'free'
    CHECK (tag IN ('free', 'question', 'info', 'humor')),
  title TEXT NOT NULL CHECK (char_length(title) <= 50),
  content TEXT NOT NULL CHECK (char_length(content) <= 5000),
  image_urls TEXT[],                            -- 최대 5장, Storage URL
  view_count INT NOT NULL DEFAULT 0,
  like_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0,
  hot_score FLOAT NOT NULL DEFAULT 0,
  is_blinded BOOLEAN NOT NULL DEFAULT FALSE,    -- 신고 5건 누적 시 자동 블라인드
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,     -- 수정됨 표시
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,    -- soft delete
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE posts IS '게시글. 각 지자체 통합 피드의 글. author_id=NULL이면 탈퇴한 사용자';
COMMENT ON COLUMN posts.is_deleted IS 'soft delete. TRUE면 클라이언트에서 비노출하되 DB에는 유지';

-- ---------------------------------------------
-- 1.7 댓글
-- author_id: nullable (탈퇴 시 익명화)
-- parent_id: 대댓글 (1depth만). ON DELETE SET NULL로 부모 삭제 시에도 대댓글 유지.
-- is_deleted: 대댓글이 있는 댓글 삭제 시 "삭제된 댓글입니다"로 표시.
-- ---------------------------------------------
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,  -- 탈퇴 시 NULL
  parent_id UUID REFERENCES comments(id) ON DELETE SET NULL,  -- 부모 삭제 시 대댓글 유지
  content TEXT NOT NULL CHECK (char_length(content) <= 1000),
  like_count INT NOT NULL DEFAULT 0,
  is_blinded BOOLEAN NOT NULL DEFAULT FALSE,
  is_edited BOOLEAN NOT NULL DEFAULT FALSE,     -- 수정됨 표시
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,    -- soft delete (대댓글 있을 때)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE comments IS '댓글. 전국 어디든 작성 가능. 대댓글은 1depth까지';
COMMENT ON COLUMN comments.is_deleted IS 'TRUE면 "삭제된 댓글입니다" 표시. 대댓글이 있을 때 사용';

-- ---------------------------------------------
-- 1.8 좋아요 (다형성 polymorphic)
-- target_type: 'post' 또는 'comment'
-- UNIQUE 제약으로 중복 좋아요 방지.
-- ---------------------------------------------
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'comment')),
  target_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, target_type, target_id)
);

-- ---------------------------------------------
-- 1.9 신고
-- UNIQUE(reporter_id, target_type, target_id)로 동일 대상 중복 신고 방지.
-- 5건 누적 시 auto_blind_on_report 트리거가 자동 블라인드.
-- ---------------------------------------------
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'comment', 'user')),
  target_id UUID NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN ('abuse', 'privacy', 'spam', 'obscene', 'other')),
  detail TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(reporter_id, target_type, target_id)   -- 중복 신고 방지
);

COMMENT ON TABLE reports IS '신고. 동일 대상 1인 1회. 5건 누적 시 자동 블라인드';

-- ---------------------------------------------
-- 1.10 북마크
-- 게시글만 북마크 가능. UNIQUE로 중복 방지.
-- ---------------------------------------------
CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, post_id)
);

-- ---------------------------------------------
-- 1.11 사용자 차단
-- 양방향 차단: A가 B를 차단하면 서로 글/댓글이 안 보임.
-- RLS에서 양방향 필터링 처리.
-- ---------------------------------------------
CREATE TABLE blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)              -- 자기 자신 차단 방지
);

-- ---------------------------------------------
-- 1.12 인사이동 이력
-- 전보 시 새 지자체로 재인증. 이전 게시글은 원래 지자체에 귀속.
-- ---------------------------------------------
CREATE TABLE transfer_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  from_municipality_id UUID REFERENCES municipalities(id),
  to_municipality_id UUID NOT NULL REFERENCES municipalities(id),
  transferred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------
-- 1.13 알림
-- 댓글/좋아요/신고결과 등. is_read 필터로 미읽음 알림 빠르게 조회.
-- ---------------------------------------------
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('comment', 'like', 'report_result', 'verification', 'system')),
  title TEXT NOT NULL,
  body TEXT,
  target_type TEXT CHECK (target_type IN ('post', 'comment')),
  target_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- =============================================
-- 2. INDEXES
-- =============================================

-- 피드 조회: 지자체 + 최신순 (블라인드/삭제 제외)
CREATE INDEX idx_posts_muni_created
  ON posts(municipality_id, created_at DESC)
  WHERE is_blinded = FALSE AND is_deleted = FALSE;

-- HOT 피드: hot_score 내림차순
CREATE INDEX idx_posts_hot
  ON posts(hot_score DESC)
  WHERE is_blinded = FALSE AND is_deleted = FALSE;

-- 태그 필터: 지자체 + 태그 + 최신순
CREATE INDEX idx_posts_muni_tag
  ON posts(municipality_id, tag, created_at DESC)
  WHERE is_blinded = FALSE AND is_deleted = FALSE;

-- 내가 쓴 글 조회 (마이페이지)
CREATE INDEX idx_posts_author_created
  ON posts(author_id, created_at DESC)
  WHERE author_id IS NOT NULL;

-- 댓글: 게시글별 시간순
CREATE INDEX idx_comments_post
  ON comments(post_id, created_at ASC);

-- 내가 쓴 댓글 조회 (마이페이지)
CREATE INDEX idx_comments_author_created
  ON comments(author_id, created_at DESC)
  WHERE author_id IS NOT NULL;

-- 한국어 검색 (pg_trgm GIN)
CREATE INDEX idx_posts_title_trgm
  ON posts USING GIN (title gin_trgm_ops);

CREATE INDEX idx_posts_content_trgm
  ON posts USING GIN (content gin_trgm_ops);

-- 좋아요 대상별 조회
CREATE INDEX idx_likes_target
  ON likes(target_type, target_id);

-- 신고 대상별 + 상태 조회
CREATE INDEX idx_reports_target
  ON reports(target_type, target_id, status);

-- 알림: 미읽음만 빠르게 (partial index)
CREATE INDEX idx_notifications_user_unread
  ON notifications(user_id, created_at DESC)
  WHERE is_read = FALSE;

-- 알림: 전체 (읽음 포함, 목록 조회용)
CREATE INDEX idx_notifications_user_all
  ON notifications(user_id, created_at DESC);

-- 차단: 양방향 필터링용. blocker + blocked 양쪽 모두 인덱스.
CREATE INDEX idx_blocks_blocker ON blocks(blocker_id);
CREATE INDEX idx_blocks_blocked ON blocks(blocked_id);

-- 이메일 도메인으로 지자체 매칭
CREATE INDEX idx_municipalities_email_domain
  ON municipalities(email_domain)
  WHERE email_domain IS NOT NULL;


-- =============================================
-- 3. ROW LEVEL SECURITY (RLS)
-- 모든 테이블에 RLS 활성화. 빠뜨리면 데이터 유출 위험.
-- =============================================

-- 3.1 municipalities: 누구나 읽기만 가능 (지자체 목록은 공개 데이터)
ALTER TABLE municipalities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "municipalities_select" ON municipalities
  FOR SELECT TO authenticated
  USING (TRUE);

-- 3.2 profiles: 본인 CRUD + 다른 사용자 기본 정보 읽기
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 다른 사용자 프로필도 읽을 수 있어야 함 (글쓴이 뱃지 등 확인용)
-- 단, 민감 정보(verified_email 등)는 클라이언트에서 필터링
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT TO authenticated
  USING (TRUE);

CREATE POLICY "profiles_insert" ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update" ON profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- profiles DELETE는 delete_my_account() RPC에서 SECURITY DEFINER로 처리
-- 일반 사용자가 직접 DELETE 못하게 정책 없음

-- 3.3 posts: 전국 열람 (블라인드/삭제/차단 필터), 글쓰기는 내 지자체만
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- SELECT: 블라인드 제외 + 양방향 차단 필터 + soft delete 제외
-- 차단된 사용자의 글은 안 보이고, 차단한 사용자에게도 내 글이 안 보임
CREATE POLICY "posts_select" ON posts
  FOR SELECT TO authenticated
  USING (
    is_blinded = FALSE
    AND is_deleted = FALSE
    AND (
      author_id IS NULL  -- 탈퇴한 사용자 글은 표시
      OR NOT EXISTS (
        SELECT 1 FROM blocks
        WHERE (blocker_id = auth.uid() AND blocked_id = posts.author_id)
           OR (blocker_id = posts.author_id AND blocked_id = auth.uid())
      )
    )
  );

-- INSERT: 소속 지자체에만 글쓰기 가능
CREATE POLICY "posts_insert" ON posts
  FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND municipality_id = (
      SELECT municipality_id FROM profiles WHERE id = auth.uid()
    )
  );

-- UPDATE: 본인 글만 수정 (author_id, municipality_id 변경 불가는 앱에서 제어)
CREATE POLICY "posts_update" ON posts
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

-- DELETE: 본인 글만 삭제 (실제로는 soft delete 권장이나, 물리 삭제도 허용)
CREATE POLICY "posts_delete" ON posts
  FOR DELETE TO authenticated
  USING (author_id = auth.uid());

-- 3.4 comments: 전국 어디든 작성 가능 (차단/블라인드 필터)
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "comments_select" ON comments
  FOR SELECT TO authenticated
  USING (
    is_blinded = FALSE
    AND (
      author_id IS NULL  -- 탈퇴한 사용자 댓글
      OR NOT EXISTS (
        SELECT 1 FROM blocks
        WHERE (blocker_id = auth.uid() AND blocked_id = comments.author_id)
           OR (blocker_id = comments.author_id AND blocked_id = auth.uid())
      )
    )
  );

CREATE POLICY "comments_insert" ON comments
  FOR INSERT TO authenticated
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "comments_update" ON comments
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid())
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "comments_delete" ON comments
  FOR DELETE TO authenticated
  USING (author_id = auth.uid());

-- 3.5 likes: 본인 것만
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "likes_select" ON likes
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "likes_insert" ON likes
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "likes_delete" ON likes
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- 3.6 reports: 본인이 신고한 것만 읽기 + 새 신고 등록
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reports_insert" ON reports
  FOR INSERT TO authenticated
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "reports_select" ON reports
  FOR SELECT TO authenticated
  USING (reporter_id = auth.uid());

-- 3.7 bookmarks: 본인 것만
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bookmarks_select" ON bookmarks
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "bookmarks_insert" ON bookmarks
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "bookmarks_delete" ON bookmarks
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- 3.8 blocks: 차단한 사람(blocker)만 관리
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "blocks_select" ON blocks
  FOR SELECT TO authenticated
  USING (blocker_id = auth.uid());

CREATE POLICY "blocks_insert" ON blocks
  FOR INSERT TO authenticated
  WITH CHECK (blocker_id = auth.uid());

CREATE POLICY "blocks_delete" ON blocks
  FOR DELETE TO authenticated
  USING (blocker_id = auth.uid());

-- 3.9 transfer_history: 본인 이력만
ALTER TABLE transfer_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "transfer_history_select" ON transfer_history
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "transfer_history_insert" ON transfer_history
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 3.10 notifications: 본인 알림만
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select" ON notifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update" ON notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_delete" ON notifications
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- 3.11 email_verifications: RLS 활성화하되 직접 접근 불가 (Edge Function에서 SECURITY DEFINER로 처리)
ALTER TABLE email_verifications ENABLE ROW LEVEL SECURITY;
-- 정책 없음 = 일반 사용자 접근 불가. Edge Function(service_role)이나 RPC(SECURITY DEFINER)에서만 접근.

-- 3.12 document_verifications: 본인 심사 내역만 조회
ALTER TABLE document_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "document_verifications_select" ON document_verifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "document_verifications_insert" ON document_verifications
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 3.13 banned_words: 읽기만 허용 (관리는 admin/service_role)
ALTER TABLE banned_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "banned_words_select" ON banned_words
  FOR SELECT TO authenticated
  USING (TRUE);


-- =============================================
-- 4. FUNCTIONS & TRIGGERS
-- =============================================

-- ---------------------------------------------
-- 4.1 updated_at 자동 갱신
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_profiles_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER tr_posts_updated
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER tr_comments_updated
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ---------------------------------------------
-- 4.2 좋아요 수 동기화
-- likes INSERT/DELETE 시 posts.like_count / comments.like_count 자동 증감.
-- SECURITY DEFINER: RLS 우회하여 다른 사용자 글의 카운트도 업데이트 가능.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION sync_like_count()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.target_type = 'post' THEN
      UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.target_id;
    ELSIF NEW.target_type = 'comment' THEN
      UPDATE comments SET like_count = like_count + 1 WHERE id = NEW.target_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.target_type = 'post' THEN
      UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.target_id;
    ELSIF OLD.target_type = 'comment' THEN
      UPDATE comments SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.target_id;
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_likes_sync
  AFTER INSERT OR DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION sync_like_count();

-- ---------------------------------------------
-- 4.3 댓글 수 동기화
-- comments INSERT/DELETE 시 posts.comment_count 자동 증감.
-- soft delete(is_deleted=TRUE) 시에는 카운트 변경하지 않음 (물리 삭제 시에만 감소).
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION sync_comment_count()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_comments_count
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION sync_comment_count();

-- ---------------------------------------------
-- 4.4 HOT 점수 계산
-- STABLE: now()를 참조하므로 IMMUTABLE이 아님.
-- (likes * 3 + comments * 2 + views * 0.1) / (age_hours + 2)^1.5
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION calculate_hot_score(
  p_likes INT,
  p_comments INT,
  p_views INT,
  p_created_at TIMESTAMPTZ
) RETURNS FLOAT AS $$
BEGIN
  RETURN (p_likes * 3.0 + p_comments * 2.0 + p_views * 0.1)
    / POWER(EXTRACT(EPOCH FROM (now() - p_created_at)) / 3600.0 + 2, 1.5);
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION calculate_hot_score IS 'HOT 점수 계산. STABLE (now() 참조). MV 대신 hot_score 컬럼 직접 갱신 방식 사용';

-- ---------------------------------------------
-- 4.5 HOT 점수 일괄 갱신
-- pg_cron으로 5분마다 실행. 7일 이내 게시글만 갱신.
-- MV 대신 posts.hot_score 컬럼을 직접 갱신하여 JOIN 없이 빠르게 조회.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION refresh_hot_scores()
RETURNS VOID
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE posts
  SET hot_score = calculate_hot_score(like_count, comment_count, view_count, created_at)
  WHERE created_at > now() - INTERVAL '7 days'
    AND is_blinded = FALSE
    AND is_deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

-- pg_cron 스케줄: 5분마다 hot_score 갱신
-- Supabase Dashboard > SQL Editor에서 실행 (pg_cron은 superuser 권한 필요)
-- SELECT cron.schedule('refresh_hot_scores', '*/5 * * * *', 'SELECT refresh_hot_scores()');

-- ---------------------------------------------
-- 4.6 신고 5건 누적 자동 블라인드
-- 새 신고가 INSERT되면, 해당 대상의 총 신고 수(dismissed 제외)를 세어
-- 5건 이상이면 자동으로 is_blinded = TRUE 설정.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION auto_blind_on_report()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM reports
  WHERE target_type = NEW.target_type
    AND target_id = NEW.target_id
    AND status != 'dismissed';

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

CREATE TRIGGER tr_auto_blind
  AFTER INSERT ON reports
  FOR EACH ROW EXECUTE FUNCTION auto_blind_on_report();

-- ---------------------------------------------
-- 4.7 대댓글 depth 제한 (1depth까지만)
-- parent_id가 지정된 댓글의 parent가 이미 대댓글(parent_id IS NOT NULL)이면 거부.
-- 즉, "대대댓글"은 불가.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION check_comment_depth()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.parent_id IS NOT NULL THEN
    -- 부모 댓글이 이미 대댓글인지 확인
    IF EXISTS (
      SELECT 1 FROM comments WHERE id = NEW.parent_id AND parent_id IS NOT NULL
    ) THEN
      RAISE EXCEPTION 'Comment depth exceeds maximum (1 level). Nested replies are not allowed.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_comment_depth
  BEFORE INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION check_comment_depth();

-- ---------------------------------------------
-- 4.8 조회수 증가 RPC
-- SECURITY DEFINER: 다른 사용자 글의 조회수도 증가시킬 수 있어야 함.
-- 클라이언트에서 글 상세 진입 시 호출.
-- 중복 조회 방지는 클라이언트(SharedPreferences)에서 처리.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION view_post(p_post_id UUID)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE posts
  SET view_count = view_count + 1
  WHERE id = p_post_id
    AND is_deleted = FALSE
    AND is_blinded = FALSE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION view_post IS '게시글 조회수 +1. 클라이언트에서 중복 방지 처리 후 호출';

-- ---------------------------------------------
-- 4.9 검색 함수
-- pg_trgm 기반 ILIKE 검색. 지자체 필터 옵션.
-- is_deleted, is_blinded 제외. 차단 사용자 필터는 RLS가 처리.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION search_posts(
  p_query TEXT,
  p_municipality_id UUID DEFAULT NULL,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS SETOF posts AS $$
BEGIN
  RETURN QUERY
    SELECT * FROM posts
    WHERE is_blinded = FALSE
      AND is_deleted = FALSE
      AND (p_municipality_id IS NULL OR municipality_id = p_municipality_id)
      AND (title ILIKE '%' || p_query || '%' OR content ILIKE '%' || p_query || '%')
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- ---------------------------------------------
-- 4.10 계정 삭제 (탈퇴) RPC
-- 물리삭제가 아닌 "익명화" 방식:
--   1. posts/comments의 author_id를 NULL로 변경 (내용은 유지)
--   2. 본인의 좋아요/북마크/차단/알림/이동이력은 물리삭제
--   3. profiles 삭제 (CASCADE로 auth.users도 삭제됨)
-- PRD 3.8: "글/댓글 삭제하지 않고 '탈퇴한 사용자'로 익명화"
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION delete_my_account()
RETURNS VOID
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  -- 1. 게시글 익명화 (author_id = NULL, 내용 유지)
  UPDATE posts SET author_id = NULL WHERE author_id = v_uid;

  -- 2. 댓글 익명화
  UPDATE comments SET author_id = NULL WHERE author_id = v_uid;

  -- 3. 좋아요 삭제 (카운트 감소는 tr_likes_sync 트리거가 처리)
  DELETE FROM likes WHERE user_id = v_uid;

  -- 4. 북마크 삭제
  DELETE FROM bookmarks WHERE user_id = v_uid;

  -- 5. 차단 삭제 (양방향 모두)
  DELETE FROM blocks WHERE blocker_id = v_uid OR blocked_id = v_uid;

  -- 6. 신고 기록은 유지 (운영 목적)

  -- 7. 알림 삭제
  DELETE FROM notifications WHERE user_id = v_uid;

  -- 8. 인사이동 이력 삭제
  DELETE FROM transfer_history WHERE user_id = v_uid;

  -- 9. 재직증명서 심사 기록 삭제
  DELETE FROM document_verifications WHERE user_id = v_uid;

  -- 10. 프로필 삭제 (auth.users ON DELETE CASCADE로 인증 정보도 삭제됨)
  DELETE FROM profiles WHERE id = v_uid;

  -- 11. auth.users 삭제
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION delete_my_account IS '계정 탈퇴. 글/댓글은 익명화(author_id=NULL), 프로필/인증정보만 삭제';

-- ---------------------------------------------
-- 4.11 is_edited 자동 설정
-- posts, comments UPDATE 시 content가 변경되면 is_edited = TRUE 자동 설정.
-- 최초 생성 시에는 FALSE 유지.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION set_is_edited()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.content IS DISTINCT FROM NEW.content THEN
    NEW.is_edited = TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_posts_edited
  BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION set_is_edited();

CREATE TRIGGER tr_comments_edited
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION set_is_edited();

-- ---------------------------------------------
-- 4.12 프로필 자동 생성
-- auth.users에 새 사용자가 생성되면 profiles 테이블에 빈 프로필 자동 생성.
-- 지자체/닉네임 등은 인증 완료 후 UPDATE로 채움.
-- ---------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO profiles (id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();


-- =============================================
-- 5. STORAGE BUCKETS
-- Supabase Dashboard에서 생성하거나 아래 SQL로 생성.
-- =============================================

-- 게시글 이미지 버킷
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-images',
  'post-images',
  TRUE,                                         -- 전체 읽기 허용
  5242880,                                      -- 5MB (5 * 1024 * 1024)
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- 재직증명서 버킷 (비공개)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'verification-docs',
  'verification-docs',
  FALSE,                                        -- 비공개 (심사용)
  10485760,                                     -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- Storage RLS: post-images
-- 업로드: 인증된 사용자, 본인 폴더에만
CREATE POLICY "post_images_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- 읽기: 전체 공개
CREATE POLICY "post_images_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'post-images');

-- 삭제: 본인 파일만
CREATE POLICY "post_images_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Storage RLS: verification-docs
-- 업로드: 인증된 사용자, 본인 폴더에만
CREATE POLICY "verification_docs_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'verification-docs'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- 읽기: 본인 파일만 (심사 결과 확인용)
CREATE POLICY "verification_docs_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'verification-docs'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );


-- =============================================
-- 6. pg_cron SCHEDULE (참고용)
-- Supabase Dashboard > SQL Editor에서 superuser로 실행해야 함.
-- 마이그레이션에서는 주석 처리.
-- =============================================

-- HOT 점수 5분마다 갱신
-- SELECT cron.schedule(
--   'refresh-hot-scores',
--   '*/5 * * * *',
--   $$SELECT refresh_hot_scores()$$
-- );

-- 만료된 이메일 인증 코드 정리 (매시간)
-- SELECT cron.schedule(
--   'cleanup-expired-email-verifications',
--   '0 * * * *',
--   $$DELETE FROM email_verifications WHERE expires_at < now() - INTERVAL '1 hour'$$
-- );
