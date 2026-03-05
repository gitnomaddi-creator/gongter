-- 대댓글 알림 지원: notify_on_comment 트리거 업데이트
-- 기존: 게시글 작성자에게만 알림
-- 변경: 대댓글이면 부모 댓글 작성자에게도 알림 (중복 방지 포함)

CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_post_author UUID;
  v_post_title TEXT;
  v_parent_author UUID;
BEGIN
  SELECT author_id, title INTO v_post_author, v_post_title
  FROM posts WHERE id = NEW.post_id;

  -- 1) 게시글 작성자에게 알림 (자기 글에 자기 댓글은 제외)
  IF v_post_author IS NOT NULL AND v_post_author != NEW.author_id THEN
    INSERT INTO notifications (user_id, type, title, body, target_type, target_id)
    VALUES (v_post_author, 'comment', '새 댓글이 달렸습니다',
            LEFT(NEW.content, 100), 'post', NEW.post_id);
  END IF;

  -- 2) 대댓글이면 부모 댓글 작성자에게도 알림
  IF NEW.parent_id IS NOT NULL THEN
    SELECT author_id INTO v_parent_author
    FROM comments WHERE id = NEW.parent_id;

    IF v_parent_author IS NOT NULL
       AND v_parent_author != NEW.author_id          -- 자기 댓글에 자기 대댓글 제외
       AND v_parent_author IS DISTINCT FROM v_post_author  -- 게시글 작성자와 중복 제외
    THEN
      INSERT INTO notifications (user_id, type, title, body, target_type, target_id)
      VALUES (v_parent_author, 'comment', '대댓글이 달렸습니다',
              LEFT(NEW.content, 100), 'post', NEW.post_id);
    END IF;
  END IF;

  RETURN NEW;
END;
$fn$ LANGUAGE plpgsql;

-- =============================================
-- FCM 푸시 전송 Webhook 트리거
-- notifications INSERT → net.http_post → Edge Function (send-push)
-- =============================================

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION send_push_webhook()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $fn$
BEGIN
  PERFORM net.http_post(
    url := 'https://lvqgmcrwdkmcgqkwkdlq.supabase.co/functions/v1/send-push',
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'notifications',
      'record', row_to_json(NEW)::jsonb
    ),
    headers := '{"Content-Type": "application/json"}'::jsonb
  );
  RETURN NEW;
END;
$fn$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_send_push_on_notification ON notifications;
CREATE TRIGGER tr_send_push_on_notification
  AFTER INSERT ON notifications
  FOR EACH ROW EXECUTE FUNCTION send_push_webhook();
