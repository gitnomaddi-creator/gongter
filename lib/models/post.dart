class Post {
  final String id;
  final String? authorId;
  final String municipalityId;
  final String tag;
  final String title;
  final String content;
  final List<String> imageUrls;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final double hotScore;
  final bool isBlinded;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? municipalityName;
  final bool? isLiked;
  final bool? isBookmarked;

  const Post({
    required this.id,
    this.authorId,
    required this.municipalityId,
    required this.tag,
    required this.title,
    required this.content,
    this.imageUrls = const [],
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.hotScore = 0,
    this.isBlinded = false,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
    this.municipalityName,
    this.isLiked,
    this.isBookmarked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      authorId: json['author_id'] as String?,
      municipalityId: json['municipality_id'] as String,
      tag: json['tag'] as String? ?? 'free',
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      hotScore: (json['hot_score'] as num?)?.toDouble() ?? 0,
      isBlinded: json['is_blinded'] as bool? ?? false,
      isEdited: json['updated_at'] != json['created_at'],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      municipalityName: json['municipality_name'] as String?,
      isLiked: json['is_liked'] as bool?,
      isBookmarked: json['is_bookmarked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'municipality_id': municipalityId,
      'tag': tag,
      'title': title,
      'content': content,
      'image_urls': imageUrls,
    };
  }
}

enum PostTag {
  free('free', '자유'),
  question('question', '질문'),
  info('info', '정보'),
  confession('confession', '고백'),
  humor('humor', '유머');

  final String value;
  final String label;
  const PostTag(this.value, this.label);

  static PostTag fromValue(String value) {
    return PostTag.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PostTag.free,
    );
  }
}
