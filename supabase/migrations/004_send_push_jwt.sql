-- send_push_webhook: Vault에서 service_role_key를 읽어 Authorization 헤더 추가
-- JWT 검증 활성화를 위한 필수 변경

CREATE OR REPLACE FUNCTION send_push_webhook()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $fn$
DECLARE
  v_service_role_key TEXT;
BEGIN
  SELECT decrypted_secret INTO v_service_role_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  PERFORM net.http_post(
    url := 'https://lvqgmcrwdkmcgqkwkdlq.supabase.co/functions/v1/send-push',
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'notifications',
      'record', row_to_json(NEW)::jsonb
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    )
  );
  RETURN NEW;
END;
$fn$ LANGUAGE plpgsql;
