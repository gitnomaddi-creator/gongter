class Comment {
  final String id;
  final String postId;
  final String? authorId;
  final String? parentId;
  final String content;
  final int likeCount;
  final bool isBlinded;
  final bool isDeleted;
  final bool isEdited;
  final bool isAuthor; // post author
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nested
  final List<Comment> replies;
  final bool? isLiked;

  const Comment({
    required this.id,
    required this.postId,
    this.authorId,
    this.parentId,
    required this.content,
    this.likeCount = 0,
    this.isBlinded = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.isAuthor = false,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
    this.isLiked,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String?,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      likeCount: json['like_count'] as int? ?? 0,
      isBlinded: json['is_blinded'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      isEdited: json['updated_at'] != json['created_at'],
      isAuthor: json['is_author'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isLiked: json['is_liked'] as bool?,
    );
  }
}
