/// 공무원 이메일 도메인 검증
///
/// 허용 도메인: korea.kr (공직자 통합메일)
class EmailValidator {
  static const _allowedDomains = [
    'korea.kr',
  ];

  /// 이메일 도메인이 허용 목록에 있는지 확인
  static bool isAllowedDomain(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex < 1) return false;

    final domain = email.substring(atIndex + 1).toLowerCase();
    return _allowedDomains.contains(domain);
  }
}
