import 'package:flutter/material.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';

class PostEditScreen extends StatefulWidget {
  final String postId;
  const PostEditScreen({super.key, required this.postId});

  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  PostTag _selectedTag = PostTag.free;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final data = await SupabaseService.getPost(widget.postId);
      if (data != null && mounted) {
        final post = Post.fromJson(data);
        _titleController.text = post.title;
        _contentController.text = post.content;
        setState(() {
          _selectedTag = PostTag.fromValue(post.tag);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await SupabaseService.updatePost(
        postId: widget.postId,
        title: title,
        content: content,
        tag: _selectedTag.value,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글 수정'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('완료',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 18,
                            color: AppColors.accent.withValues(alpha: 0.8)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(AppConstants.legalReminder,
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('태그',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PostTag.values.map((tag) {
                      final selected = _selectedTag == tag;
                      return ChoiceChip(
                        label: Text(
                          tag.label,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: selected ? AppColors.primary : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedTag = tag);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    maxLength: AppConstants.maxTitleLength,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      hintText: '제목을 입력하세요',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    maxLength: AppConstants.maxContentLength,
                    maxLines: null,
                    minLines: 10,
                    decoration: const InputDecoration(
                      labelText: '내용',
                      hintText: '내용을 입력하세요',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
