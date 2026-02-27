-- =============================================
-- 공터 (Gongter) - 출시 전 DB 최적화
-- v1.1 → v1.2 마이그레이션
-- 작성일: 2026-02-27
-- =============================================
-- 실행 방법: Supabase Dashboard > SQL Editor에서 실행

-- =============================================
-- B-1. RLS posts_select / comments_select 에서 blocks 서브쿼리 제거
-- 이유: 매 행마다 blocks NOT EXISTS 서브쿼리 → 성능 병목
--       클라이언트에서 이미 차단 필터링 구현됨 (이중 작업 제거)
-- =============================================

DROP POLICY IF EXISTS "posts_select" ON posts;
CREATE POLICY "posts_select" ON posts
  FOR SELECT TO authenticated
  USING (is_blinded = FALSE AND is_deleted = FALSE);

DROP POLICY IF EXISTS "comments_select" ON comments;
CREATE POLICY "comments_select" ON comments
  FOR SELECT TO authenticated
  USING (is_blinded = FALSE);

-- =============================================
-- B-2. toggle_like / toggle_bookmark RPC
-- 이유: SELECT 확인 → DELETE/INSERT = 2 round-trip + race condition
--       서버에서 원자적으로 처리 (1 round-trip)
-- =============================================

CREATE OR REPLACE FUNCTION toggle_like(
  p_target_type TEXT,
  p_target_id UUID
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_existing UUID;
  v_result BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id INTO v_existing
  FROM likes
  WHERE user_id = v_uid
    AND target_type = p_target_type
    AND target_id = p_target_id;

  IF v_existing IS NOT NULL THEN
    DELETE FROM likes WHERE id = v_existing;
    v_result := FALSE;  -- unliked
  ELSE
    INSERT INTO likes (user_id, target_type, target_id)
    VALUES (v_uid, p_target_type, p_target_id);
    v_result := TRUE;   -- liked
  END IF;

  RETURN json_build_object('liked', v_result);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION toggle_like IS '좋아요 토글. 원자적 처리. liked=true/false 반환';

CREATE OR REPLACE FUNCTION toggle_bookmark(
  p_post_id UUID
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_existing UUID;
  v_result BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id INTO v_existing
  FROM bookmarks
  WHERE user_id = v_uid
    AND post_id = p_post_id;

  IF v_existing IS NOT NULL THEN
    DELETE FROM bookmarks WHERE id = v_existing;
    v_result := FALSE;  -- unbookmarked
  ELSE
    INSERT INTO bookmarks (user_id, post_id)
    VALUES (v_uid, p_post_id);
    v_result := TRUE;   -- bookmarked
  END IF;

  RETURN json_build_object('bookmarked', v_result);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION toggle_bookmark IS '북마크 토글. 원자적 처리. bookmarked=true/false 반환';

-- =============================================
-- B-3. get_post_detail RPC
-- 이유: 게시글 조회 + 좋아요 상태 + 북마크 상태 = 3 round-trip → 1
-- =============================================

CREATE OR REPLACE FUNCTION get_post_detail(p_post_id UUID)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_post RECORD;
  v_municipality_name TEXT;
  v_is_liked BOOLEAN := FALSE;
  v_is_bookmarked BOOLEAN := FALSE;
BEGIN
  -- 게시글 조회
  SELECT * INTO v_post
  FROM posts
  WHERE id = p_post_id;

  IF v_post IS NULL THEN
    RETURN NULL;
  END IF;

  -- 지자체 이름
  SELECT name INTO v_municipality_name
  FROM municipalities
  WHERE id = v_post.municipality_id;

  -- 좋아요/북마크 상태 (로그인한 경우)
  IF v_uid IS NOT NULL THEN
    SELECT EXISTS(
      SELECT 1 FROM likes
      WHERE user_id = v_uid AND target_type = 'post' AND target_id = p_post_id
    ) INTO v_is_liked;

    SELECT EXISTS(
      SELECT 1 FROM bookmarks
      WHERE user_id = v_uid AND post_id = p_post_id
    ) INTO v_is_bookmarked;
  END IF;

  RETURN json_build_object(
    'id', v_post.id,
    'author_id', v_post.author_id,
    'municipality_id', v_post.municipality_id,
    'tag', v_post.tag,
    'title', v_post.title,
    'content', v_post.content,
    'image_urls', v_post.image_urls,
    'view_count', v_post.view_count,
    'like_count', v_post.like_count,
    'comment_count', v_post.comment_count,
    'hot_score', v_post.hot_score,
    'is_blinded', v_post.is_blinded,
    'is_edited', v_post.is_edited,
    'is_deleted', v_post.is_deleted,
    'created_at', v_post.created_at,
    'updated_at', v_post.updated_at,
    'municipalities', json_build_object('name', v_municipality_name),
    'is_liked', v_is_liked,
    'is_bookmarked', v_is_bookmarked
  );
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_post_detail IS '게시글 상세 조회 (좋아요/북마크 상태 포함). 3 round-trip → 1';

-- =============================================
-- FCM 토큰 컬럼 추가
-- =============================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- =============================================
-- 댓글 알림 트리거
-- 새 댓글 작성 시 게시글 작성자에게 알림 INSERT
-- (자기 글에 자기가 댓글 달면 알림 안 감)
-- =============================================

CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_post_author UUID;
  v_post_title TEXT;
BEGIN
  -- 게시글 작성자 조회
  SELECT author_id, title INTO v_post_author, v_post_title
  FROM posts
  WHERE id = NEW.post_id;

  -- 자기 글에 자기가 댓글 달면 알림 생략
  IF v_post_author IS NULL OR v_post_author = NEW.author_id THEN
    RETURN NEW;
  END IF;

  INSERT INTO notifications (user_id, type, title, body, target_type, target_id)
  VALUES (
    v_post_author,
    'comment',
    '새 댓글이 달렸습니다',
    LEFT(NEW.content, 100),
    'post',
    NEW.post_id
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 기존 트리거가 있을 수 있으므로 DROP 후 재생성
DROP TRIGGER IF EXISTS tr_notify_on_comment ON comments;
CREATE TRIGGER tr_notify_on_comment
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION notify_on_comment();

-- =============================================
-- A-6. pg_cron 스케줄 활성화
-- 주의: 이 부분은 Supabase SQL Editor에서 별도로 실행해야 할 수 있음
-- =============================================

SELECT cron.schedule(
  'refresh-hot-scores',
  '*/5 * * * *',
  $$SELECT refresh_hot_scores()$$
);

SELECT cron.schedule(
  'cleanup-expired-email-verifications',
  '0 * * * *',
  $$DELETE FROM email_verifications WHERE expires_at < now() - INTERVAL '1 hour'$$
);
