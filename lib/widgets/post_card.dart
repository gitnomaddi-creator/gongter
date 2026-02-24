import 'package:flutter/material.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Post post;
  final bool showMunicipality;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.showMunicipality = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: tag + municipality + time
              Row(
                children: [
                  _buildTag(),
                  if (showMunicipality && post.municipalityName != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      post.municipalityName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    timeago.format(post.createdAt, locale: 'ko'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (post.isEdited) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '수정됨',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Content preview
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer: likes, comments, views
              Row(
                children: [
                  _buildStat(Icons.favorite_border, post.likeCount),
                  const SizedBox(width: 16),
                  _buildStat(Icons.chat_bubble_outline, post.commentCount),
                  const SizedBox(width: 16),
                  _buildStat(Icons.visibility_outlined, post.viewCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag() {
    final tag = PostTag.fromValue(post.tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag.label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
