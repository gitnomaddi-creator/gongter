import 'package:flutter/material.dart';
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
  final _commentController = TextEditingController();
  String? _replyToId;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() => _loading = true);
    try {
      final postData = await SupabaseService.getPost(widget.postId);
      final commentData = await SupabaseService.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _post = postData != null ? Post.fromJson(postData) : null;
          _comments = commentData.map((e) => Comment.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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
      _loadPost();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    try {
      await SupabaseService.toggleLike(
          targetType: 'post', targetId: _post!.id);
      _loadPost();
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_post == null) return;
    try {
      await SupabaseService.toggleBookmark(_post!.id);
      _loadPost();
    } catch (_) {}
  }

  void _showReportDialog() {
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
                      targetType: 'post',
                      targetId: _post!.id,
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
                if (value == 'delete') {
                  final nav = Navigator.of(context);
                  await SupabaseService.deletePost(_post!.id);
                  if (!mounted) return;
                  nav.pop();
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              onPressed: _post != null ? _showReportDialog : null,
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
                                    child: Image.network(url,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 16),
                            // Actions
                            Row(
                              children: [
                                _buildAction(
                                  Icons.favorite_border,
                                  '${_post!.likeCount}',
                                  _toggleLike,
                                ),
                                const SizedBox(width: 24),
                                _buildAction(
                                  Icons.bookmark_border,
                                  '북마크',
                                  _toggleBookmark,
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

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(Comment comment) {
    final isDeleted = comment.isDeleted;
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
                '익명',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDeleted ? AppColors.textSecondary : null,
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
              ],
            ),
        ],
      ),
    );
  }
}
