class Municipality {
  final String id;
  final String name;
  final String fullName;
  final String adminCode;
  final int level; // 1=광역, 2=기초
  final String? parentId;
  final String? emailDomain;

  const Municipality({
    required this.id,
    required this.name,
    required this.fullName,
    required this.adminCode,
    required this.level,
    this.parentId,
    this.emailDomain,
  });

  factory Municipality.fromJson(Map<String, dynamic> json) {
    return Municipality(
      id: json['id'] as String,
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      adminCode: json['admin_code'] as String,
      level: json['level'] as int,
      parentId: json['parent_id'] as String?,
      emailDomain: json['email_domain'] as String?,
    );
  }

  bool get isMetro => level == 1;
  bool get isBasic => level == 2;
}
