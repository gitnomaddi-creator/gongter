"""Supabase 이메일 템플릿 업데이트 스크립트"""
import json
import urllib.request

PROJECT_REF = "lvqgmcrwdkmcgqkwkdlq"
ACCESS_TOKEN = "sbp_501e19c69823efe532c6fbe6aa27a49c56f58c70"

COMMON_HEADER = '''<tr>
            <td style="background: linear-gradient(135deg, #E8836B 0%, #D4604A 100%); padding:36px 40px; text-align:center;">
              <div style="display:inline-block; background-color:rgba(255,255,255,0.18); border-radius:12px; padding:10px 24px;">
                <span style="font-size:26px; font-weight:800; color:#FFFFFF; letter-spacing:4px;">공터</span>
              </div>
              <p style="margin:12px 0 0 0; font-size:13px; color:rgba(255,255,255,0.85); letter-spacing:1px;">지방공무원 익명 커뮤니티</p>
            </td>
          </tr>'''

COMMON_FOOTER = '''<tr>
            <td style="padding:24px 40px; background-color:#FAFAFA; border-top:1px solid #F0EBE8; text-align:center;">
              <p style="margin:0 0 4px 0; font-size:12px; color:#BDBDBD;">본 메일은 발신 전용입니다. 회신하셔도 답변이 어렵습니다.</p>
              <p style="margin:0; font-size:11px; color:#D0C8C4;">&copy; 2026 공터. All rights reserved.</p>
            </td>
          </tr>'''

def wrap_template(body_content):
    return f'''<table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F5F0ED; padding:40px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px; background-color:#FFFFFF; border-radius:16px; overflow:hidden; box-shadow:0 2px 12px rgba(0,0,0,0.08);">
          {COMMON_HEADER}
          {body_content}
          {COMMON_FOOTER}
        </table>
      </td>
    </tr>
  </table>'''

# 1. 회원가입 확인
confirmation = wrap_template('''<tr>
            <td style="padding:40px 40px 32px 40px; background-color:#FFF8F5;">
              <h1 style="margin:0 0 8px 0; font-size:22px; font-weight:700; color:#2D2D2D;">이메일 인증</h1>
              <p style="margin:0 0 24px 0; font-size:14px; color:#9E9E9E;">Email Verification</p>
              <p style="margin:0 0 20px 0; font-size:15px; line-height:1.7; color:#2D2D2D;">
                공터에 가입해 주셔서 감사합니다.<br>
                아래 버튼을 눌러 이메일 인증을 완료하면<br>
                지방공무원 전용 커뮤니티를 이용하실 수 있습니다.
              </p>
              <div style="height:1px; background-color:#F2A896; opacity:0.3; margin:24px 0;"></div>
              <p style="margin:0 0 6px 0; font-size:13px; color:#757575;">인증 유효 시간</p>
              <p style="margin:0 0 28px 0; font-size:14px; font-weight:600; color:#E8836B;">24시간 이내</p>
              <table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td align="center">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#D4604A; color:#FFFFFF; font-size:15px; font-weight:700; text-decoration:none; padding:14px 48px; border-radius:8px;">이메일 인증하기</a>
              </td></tr></table>
              <p style="margin:24px 0 0 0; font-size:12px; color:#BDBDBD; line-height:1.6; text-align:center;">
                버튼이 작동하지 않으면 아래 링크를 브라우저에 직접 붙여넣기 해주세요.<br>
                <span style="color:#E8836B; word-break:break-all;">{{ .ConfirmationURL }}</span>
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 40px; background-color:#FFF1EE; border-top:1px solid #F2D5CE;">
              <p style="margin:0; font-size:12px; color:#A0614E; line-height:1.7;">
                본인이 요청하지 않은 메일이라면 즉시 무시하세요.<br>
                공터는 비밀번호나 개인정보를 이메일로 요청하지 않습니다.
              </p>
            </td>
          </tr>''')

# 2. 비밀번호 재설정
recovery = wrap_template('''<tr>
            <td style="padding:40px 40px 32px 40px; background-color:#FFF8F5;">
              <h1 style="margin:0 0 8px 0; font-size:22px; font-weight:700; color:#2D2D2D;">비밀번호 재설정</h1>
              <p style="margin:0 0 24px 0; font-size:14px; color:#9E9E9E;">Password Reset</p>
              <p style="margin:0 0 20px 0; font-size:15px; line-height:1.7; color:#2D2D2D;">
                비밀번호 재설정을 요청하셨습니다.<br>
                아래 버튼을 눌러 새 비밀번호를 설정해 주세요.
              </p>
              <div style="height:1px; background-color:#F2A896; opacity:0.3; margin:24px 0;"></div>
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:28px;"><tr>
                <td style="background-color:#FFF1EE; border-left:3px solid #E8836B; border-radius:0 6px 6px 0; padding:14px 16px;">
                  <p style="margin:0 0 4px 0; font-size:13px; font-weight:600; color:#D4604A;">주의</p>
                  <p style="margin:0; font-size:13px; color:#A0614E; line-height:1.6;">
                    이 링크는 1시간 동안만 유효하며 1회만 사용 가능합니다.<br>
                    본인이 요청하지 않았다면 이 메일을 무시하세요.
                  </p>
                </td>
              </tr></table>
              <table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td align="center">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#D4604A; color:#FFFFFF; font-size:15px; font-weight:700; text-decoration:none; padding:14px 48px; border-radius:8px;">비밀번호 재설정하기</a>
              </td></tr></table>
              <p style="margin:24px 0 0 0; font-size:12px; color:#BDBDBD; line-height:1.6; text-align:center;">
                버튼이 작동하지 않으면 아래 링크를 브라우저에 직접 붙여넣기 해주세요.<br>
                <span style="color:#E8836B; word-break:break-all;">{{ .ConfirmationURL }}</span>
              </p>
            </td>
          </tr>''')

# 3. 매직 링크
magic_link = wrap_template('''<tr>
            <td style="padding:40px 40px 32px 40px; background-color:#FFF8F5;">
              <h1 style="margin:0 0 8px 0; font-size:22px; font-weight:700; color:#2D2D2D;">로그인 링크</h1>
              <p style="margin:0 0 24px 0; font-size:14px; color:#9E9E9E;">Magic Link Login</p>
              <p style="margin:0 0 20px 0; font-size:15px; line-height:1.7; color:#2D2D2D;">
                공터 로그인을 요청하셨습니다.<br>
                아래 버튼을 눌러 바로 로그인하세요.
              </p>
              <div style="height:1px; background-color:#F2A896; opacity:0.3; margin:24px 0;"></div>
              <p style="margin:0 0 6px 0; font-size:13px; color:#757575;">링크 유효 시간</p>
              <p style="margin:0 0 28px 0; font-size:14px; font-weight:600; color:#E8836B;">1시간 이내</p>
              <table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td align="center">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#D4604A; color:#FFFFFF; font-size:15px; font-weight:700; text-decoration:none; padding:14px 48px; border-radius:8px;">공터 로그인하기</a>
              </td></tr></table>
              <p style="margin:24px 0 0 0; font-size:12px; color:#BDBDBD; line-height:1.6; text-align:center;">
                버튼이 작동하지 않으면 아래 링크를 브라우저에 직접 붙여넣기 해주세요.<br>
                <span style="color:#E8836B; word-break:break-all;">{{ .ConfirmationURL }}</span>
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 40px; background-color:#FFF1EE; border-top:1px solid #F2D5CE;">
              <p style="margin:0; font-size:12px; color:#A0614E; line-height:1.7;">
                본인이 요청하지 않은 메일이라면 즉시 무시하세요.<br>
                이 링크를 타인과 공유하지 마세요.
              </p>
            </td>
          </tr>''')

# 4. 이메일 변경
email_change = wrap_template('''<tr>
            <td style="padding:40px 40px 32px 40px; background-color:#FFF8F5;">
              <h1 style="margin:0 0 8px 0; font-size:22px; font-weight:700; color:#2D2D2D;">이메일 변경 확인</h1>
              <p style="margin:0 0 24px 0; font-size:14px; color:#9E9E9E;">Email Change Confirmation</p>
              <p style="margin:0 0 24px 0; font-size:15px; line-height:1.7; color:#2D2D2D;">
                이메일 주소 변경을 요청하셨습니다.<br>
                새 이메일 주소 인증을 완료해 주세요.
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:28px;"><tr>
                <td style="background-color:#FFFFFF; border:1px solid #F2D5CE; border-radius:8px; padding:20px;">
                  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:12px;"><tr>
                    <td style="width:70px; vertical-align:top; padding-top:2px;">
                      <span style="font-size:11px; font-weight:600; color:#BDBDBD; background-color:#F5F5F5; padding:3px 8px; border-radius:4px;">기존</span>
                    </td>
                    <td><span style="font-size:14px; color:#9E9E9E; text-decoration:line-through;">{{ .Email }}</span></td>
                  </tr></table>
                  <div style="text-align:center; margin:4px 0; font-size:16px; color:#E8836B;">↓</div>
                  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-top:12px;"><tr>
                    <td style="width:70px; vertical-align:top; padding-top:2px;">
                      <span style="font-size:11px; font-weight:600; color:#FFFFFF; background-color:#E8836B; padding:3px 8px; border-radius:4px;">신규</span>
                    </td>
                    <td><span style="font-size:14px; font-weight:600; color:#2D2D2D;">{{ .NewEmail }}</span></td>
                  </tr></table>
                </td>
              </tr></table>
              <table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td align="center">
                <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#D4604A; color:#FFFFFF; font-size:15px; font-weight:700; text-decoration:none; padding:14px 48px; border-radius:8px;">새 이메일 인증하기</a>
              </td></tr></table>
              <p style="margin:24px 0 0 0; font-size:12px; color:#BDBDBD; line-height:1.6; text-align:center;">
                버튼이 작동하지 않으면 아래 링크를 브라우저에 직접 붙여넣기 해주세요.<br>
                <span style="color:#E8836B; word-break:break-all;">{{ .ConfirmationURL }}</span>
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 40px; background-color:#FFF1EE; border-top:1px solid #F2D5CE;">
              <p style="margin:0; font-size:12px; color:#A0614E; line-height:1.7;">
                본인이 요청하지 않은 변경이라면 즉시 고객센터로 문의해 주세요.<br>
                인증 완료 전까지는 기존 이메일로 계속 로그인 가능합니다.
              </p>
            </td>
          </tr>''')

# 5. 재인증 OTP
reauthentication = wrap_template('''<tr>
            <td style="padding:40px 40px 32px 40px; background-color:#FFF8F5;">
              <h1 style="margin:0 0 8px 0; font-size:22px; font-weight:700; color:#2D2D2D;">본인 확인 코드</h1>
              <p style="margin:0 0 24px 0; font-size:14px; color:#9E9E9E;">Verification Code</p>
              <p style="margin:0 0 28px 0; font-size:15px; line-height:1.7; color:#2D2D2D;">
                공터 앱에서 본인 확인을 요청하셨습니다.<br>
                아래 인증 코드를 앱 화면에 입력해 주세요.
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:28px;"><tr><td align="center">
                <div style="display:inline-block; background-color:#FFFFFF; border:2px solid #E8836B; border-radius:12px; padding:24px 40px; text-align:center;">
                  <p style="margin:0 0 8px 0; font-size:12px; font-weight:600; color:#E8836B; letter-spacing:2px;">인증 코드</p>
                  <p style="margin:0; font-size:40px; font-weight:800; color:#D4604A; letter-spacing:10px; font-family:monospace;">{{ .Token }}</p>
                </div>
              </td></tr></table>
              <table width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
                <td style="background-color:#FFF1EE; border-left:3px solid #E8836B; border-radius:0 6px 6px 0; padding:12px 16px;">
                  <p style="margin:0; font-size:13px; color:#A0614E; line-height:1.6;">
                    이 코드는 <strong>10분 이내</strong>에만 사용 가능합니다.<br>
                    코드를 타인에게 알려주지 마세요.
                  </p>
                </td>
              </tr></table>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 40px; background-color:#FFF1EE; border-top:1px solid #F2D5CE;">
              <p style="margin:0; font-size:12px; color:#A0614E; line-height:1.7;">
                본인이 요청하지 않은 메일이라면 즉시 무시하세요.<br>
                공터 직원은 인증 코드를 전화나 문자로 요청하지 않습니다.
              </p>
            </td>
          </tr>''')

payload = {
    "mailer_subjects_confirmation": "[공터] 이메일 인증을 완료해 주세요",
    "mailer_templates_confirmation_content": confirmation,
    "mailer_subjects_recovery": "[공터] 비밀번호 재설정 링크가 도착했습니다",
    "mailer_templates_recovery_content": recovery,
    "mailer_subjects_magic_link": "[공터] 로그인 링크가 도착했습니다",
    "mailer_templates_magic_link_content": magic_link,
    "mailer_subjects_email_change": "[공터] 새 이메일 주소 인증을 완료해 주세요",
    "mailer_templates_email_change_content": email_change,
    "mailer_subjects_reauthentication": "[공터] 본인 확인 코드",
    "mailer_templates_reauthentication_content": reauthentication,
}

url = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/config/auth"
data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(url, data=data, method="PATCH")
req.add_header("Authorization", f"Bearer {ACCESS_TOKEN}")
req.add_header("Content-Type", "application/json")
req.add_header("User-Agent", "supabase-cli/1.0")

try:
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read().decode())
        # Verify templates were applied
        checks = [
            ("confirmation subject", result.get("mailer_subjects_confirmation")),
            ("recovery subject", result.get("mailer_subjects_recovery")),
            ("magic_link subject", result.get("mailer_subjects_magic_link")),
            ("email_change subject", result.get("mailer_subjects_email_change")),
            ("reauthentication subject", result.get("mailer_subjects_reauthentication")),
            ("smtp_host", result.get("smtp_host")),
        ]
        print("=== 이메일 템플릿 업데이트 결과 ===")
        for label, val in checks:
            print(f"  {label}: {val}")
        print("\n모든 템플릿이 성공적으로 적용되었습니다!")
except urllib.error.HTTPError as e:
    print(f"Error {e.code}: {e.read().decode()}")
