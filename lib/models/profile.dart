class Profile {
  final String id;
  final String? municipalityId;
  final String? nickname;
  final bool isVerified;
  final String? verificationMethod;
  final String? municipalityName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.municipalityId,
    this.nickname,
    this.isVerified = false,
    this.verificationMethod,
    this.municipalityName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      municipalityId: json['municipality_id'] as String?,
      nickname: json['nickname'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationMethod: json['verification_method'] as String?,
      municipalityName: json['municipality_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
