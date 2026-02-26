import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/models/comment.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/widgets/banner_ad_widget.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  List<Comment> _comments = [];
  bool _loading = true;
  bool _togglingLike = false;
  bool _togglingBookmark = false;
  final _commentController = TextEditingController();
  String? _replyToId;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  /// Initial load: increment view count once, then load post + comments
  Future<void> _initialLoad() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.incrementViewCount(widget.postId);
      await _fetchPostAndComments();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Reload post + comments without incrementing view count
  Future<void> _loadPost() async {
    setState(() => _loading = true);
    try {
      await _fetchPostAndComments();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchPostAndComments() async {
    final postData = await SupabaseService.getPost(widget.postId);
    final commentData = await SupabaseService.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _post = postData != null ? Post.fromJson(postData) : null;
        _comments = commentData.map((e) => Comment.fromJson(e)).toList();
        _loading = false;
      });
    }
  }

  /// Reload only comments (for after comment submit/delete)
  Future<void> _loadComments() async {
    try {
      final commentData = await SupabaseService.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = commentData.map((e) => Comment.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    try {
      await SupabaseService.createComment(
        postId: widget.postId,
        content: content,
        parentId: _replyToId,
      );
      _commentController.clear();
      setState(() => _replyToId = null);
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null || _togglingLike) return;
    setState(() => _togglingLike = true);
    try {
      await SupabaseService.toggleLike(
          targetType: 'post', targetId: _post!.id);
      // Reload post only (no view count increment)
      final postData = await SupabaseService.getPost(widget.postId);
      if (mounted && postData != null) {
        setState(() => _post = Post.fromJson(postData));
      }
    } catch (_) {}
    if (mounted) setState(() => _togglingLike = false);
  }

  Future<void> _toggleBookmark() async {
    if (_post == null || _togglingBookmark) return;
    setState(() => _togglingBookmark = true);
    try {
      await SupabaseService.toggleBookmark(_post!.id);
      // Reload post to get updated bookmark state
      final postData = await SupabaseService.getPost(widget.postId);
      if (mounted && postData != null) {
        setState(() => _post = Post.fromJson(postData));
      }
    } catch (_) {}
    if (mounted) setState(() => _togglingBookmark = false);
  }

  Future<void> _blockUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사용자 차단'),
        content: const Text('이 사용자를 차단하시겠습니까?\n차단하면 이 사용자의 글과 댓글이 보이지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('차단', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.blockUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자를 차단했습니다')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmDeletePost() async {
    final nav = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.deletePost(_post!.id);
      if (!mounted) return;
      nav.pop();
    }
  }

  void _showReportDialog({required String targetType, required String targetId}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신고'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReportReason.labels.entries
              .map(
                (e) => ListTile(
                  title: Text(e.value),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await SupabaseService.report(
                      targetType: targetType,
                      targetId: targetId,
                      reason: e.key,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('신고가 접수되었습니다')),
                      );
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          if (_post != null &&
              _post!.authorId == SupabaseService.currentUserId)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await context.push<bool>('/edit/${_post!.id}');
                  if (result == true) _loadPost();
                } else if (value == 'delete') {
                  _confirmDeletePost();
                }
              },
            )
          else if (_post != null)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'report', child: Text('신고')),
                if (_post!.authorId != null)
                  const PopupMenuItem(
                    value: 'block',
                    child: Text('이 사용자 차단',
                        style: TextStyle(color: AppColors.error)),
                  ),
              ],
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog(
                      targetType: 'post', targetId: _post!.id);
                } else if (value == 'block' && _post!.authorId != null) {
                  _blockUser(_post!.authorId!);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('게시글을 찾을 수 없습니다'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPost,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Post header
                            Row(
                              children: [
                                _buildTag(_post!.tag),
                                const Spacer(),
                                Text(
                                  timeago.format(_post!.createdAt, locale: 'ko'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Title
                            Text(
                              _post!.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_post!.isEdited)
                              const Text(
                                '수정됨',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const SizedBox(height: 16),
                            // Content
                            Text(
                              _post!.content,
                              style: const TextStyle(
                                  fontSize: 15, height: 1.6),
                            ),
                            // Images
                            if (_post!.imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              for (final url in _post!.imageUrls)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                            child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 16),
                            // Actions
                            Row(
                              children: [
                                _buildAction(
                                  _post!.isLiked == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  '${_post!.likeCount}',
                                  _togglingLike ? null : _toggleLike,
                                  color: _post!.isLiked == true
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 24),
                                _buildAction(
                                  _post!.isBookmarked == true
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  '북마크',
                                  _togglingBookmark ? null : _toggleBookmark,
                                  color: _post!.isBookmarked == true
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const Spacer(),
                                Text(
                                  '조회 ${_post!.viewCount}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            // Comments
                            Text(
                              '댓글 ${_comments.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final comment in _comments)
                              _buildCommentTile(comment),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                    const BannerAdWidget(),
                    // Comment input
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            if (_replyToId != null)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _replyToId = null),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('답글',
                                          style: TextStyle(fontSize: 12)),
                                      SizedBox(width: 4),
                                      Icon(Icons.close, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: '댓글을 입력하세요',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                maxLines: null,
                              ),
                            ),
                            IconButton(
                              onPressed: _submitComment,
                              icon: const Icon(Icons.send,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTag(String tagValue) {
    final tag = PostTag.fromValue(tagValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.label,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback? onTap,
      {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 14, color: c)),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCommentLike(String commentId) async {
    try {
      await SupabaseService.toggleLike(
          targetType: 'comment', targetId: commentId);
      _loadComments();
    } catch (_) {}
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.deleteComment(commentId);
      _loadComments();
    }
  }

  /// Get anonymous number for a comment author within this post
  String _getAnonLabel(Comment comment) {
    if (comment.isAuthor) return '글쓴이';
    if (comment.authorId == SupabaseService.currentUserId) return '나';
    // Build unique author list in order of first appearance
    final authorOrder = <String>[];
    for (final c in _comments) {
      if (c.authorId != null &&
          c.authorId != _post?.authorId &&
          c.authorId != SupabaseService.currentUserId &&
          !authorOrder.contains(c.authorId)) {
        authorOrder.add(c.authorId!);
      }
    }
    final idx = authorOrder.indexOf(comment.authorId ?? '');
    return '익명${idx + 1}';
  }

  Widget _buildCommentTile(Comment comment) {
    final isDeleted = comment.isDeleted;
    final isMyComment =
        comment.authorId == SupabaseService.currentUserId;
    final anonLabel = _getAnonLabel(comment);
    return Padding(
      padding: EdgeInsets.only(
        left: comment.parentId != null ? 32 : 0,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                anonLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: comment.isAuthor
                      ? AppColors.primary
                      : isDeleted
                          ? AppColors.textSecondary
                          : null,
                ),
              ),
              if (comment.isAuthor) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '글쓴이',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                timeago.format(comment.createdAt, locale: 'ko'),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isDeleted ? '삭제된 댓글입니다' : comment.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDeleted ? AppColors.textSecondary : null,
              fontStyle: isDeleted ? FontStyle.italic : null,
            ),
          ),
          if (!isDeleted)
            Row(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _replyToId = comment.id),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('답글', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _toggleCommentLike(comment.id),
                  icon: const Icon(Icons.favorite_border, size: 14),
                  label: Text('${comment.likeCount}',
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                  ),
                ),
                if (isMyComment) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteComment(comment.id),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('삭제', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showReportDialog(
                        targetType: 'comment', targetId: comment.id),
                    icon: const Icon(Icons.flag_outlined, size: 14),
                    label: const Text('신고', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                  if (comment.authorId != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _blockUser(comment.authorId!),
                      icon: const Icon(Icons.block, size: 14),
                      label: const Text('차단', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                      ),
                    ),
                  ],
                ],
              ],
            ),
        ],
      ),
    );
  }
}
