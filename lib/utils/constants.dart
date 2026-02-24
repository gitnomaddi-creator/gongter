class AppConstants {
  // Supabase
  static const supabaseUrl = 'https://lvqgmcrwdkmcgqkwkdlq.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2cWdtY3J3ZGttY2dxa3drZGxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5Mjk3MzAsImV4cCI6MjA4NzUwNTczMH0.sypanV0Lp5aDE9zvoClGxasRxyxlR1V9JPhWyxNbnKw';

  // Limits
  static const maxTitleLength = 50;
  static const maxContentLength = 5000;
  static const maxImages = 5;
  static const maxImageSizeMb = 5;
  static const maxNicknameLength = 10;
  static const minNicknameLength = 2;

  // Pagination
  static const pageSize = 20;

  // Reports
  static const autoBlindThreshold = 5;

  // Legal notice text
  static const legalNotice = '''
[공무원법 주의사항]
- 직무상 비밀 누설 금지 (제60조)
- 품위유지 의무 (제63조)
- 정치 중립 의무 (제65조)
- 본 앱의 게시글은 개인 의견이며, 법적 책임은 작성자 본인에게 있습니다.''';

  static const legalReminder = '직무상 비밀 누설, 정치적 편향 발언 주의';
}

class ReportReason {
  static const abuse = 'abuse';
  static const privacy = 'privacy';
  static const spam = 'spam';
  static const obscene = 'obscene';
  static const other = 'other';

  static const labels = {
    abuse: '욕설/비방',
    privacy: '개인정보 노출',
    spam: '스팸/광고',
    obscene: '음란',
    other: '기타',
  };
}
