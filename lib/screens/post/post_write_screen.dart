import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';

class PostWriteScreen extends StatefulWidget {
  const PostWriteScreen({super.key});

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  PostTag _selectedTag = PostTag.free;
  final List<File> _images = [];
  bool _submitting = false;

  Future<void> _pickImage() async {
    if (_images.length >= AppConstants.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지는 최대 ${AppConstants.maxImages}장까지 첨부할 수 있습니다')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
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
    if (title.length > AppConstants.maxTitleLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('제목은 ${AppConstants.maxTitleLength}자 이내로 작성해주세요')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final profile = await SupabaseService.getProfile();
      final municipalityId = profile?['municipality_id'] as String?;
      if (municipalityId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('소속 지자체가 설정되지 않았습니다')),
          );
        }
        return;
      }

      // Upload images
      List<String> imageUrls = [];
      for (final img in _images) {
        final url = await SupabaseService.uploadPostImage(img);
        imageUrls.add(url);
      }

      await SupabaseService.createPost(
        municipalityId: municipalityId,
        tag: _selectedTag.value,
        title: title,
        content: content,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('글 작성에 실패했습니다')),
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
        title: const Text('글쓰기'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legal reminder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18,
                      color: AppColors.accent.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      AppConstants.legalReminder,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tag selection
            const Text('태그', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PostTag.values.map((tag) {
                final selected = _selectedTag == tag;
                return ChoiceChip(
                  label: Text(tag.label),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  onSelected: (val) {
                    if (val) setState(() => _selectedTag = tag);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Title
            TextField(
              controller: _titleController,
              maxLength: AppConstants.maxTitleLength,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '제목을 입력하세요',
              ),
            ),
            const SizedBox(height: 16),
            // Content
            TextField(
              controller: _contentController,
              maxLength: AppConstants.maxContentLength,
              maxLines: null,
              minLines: 8,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '내용을 입력하세요',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            // Images
            Row(
              children: [
                const Text('이미지',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${_images.length}/${AppConstants.maxImages}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add button
                  if (_images.length < AppConstants.maxImages)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_photo_alternate,
                            size: 32, color: Colors.grey.shade400),
                      ),
                    ),
                  // Previews
                  for (var i = 0; i < _images.length; i++)
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_images[i], fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _images.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
