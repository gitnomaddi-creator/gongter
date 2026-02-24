import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyCommentsScreen extends StatefulWidget {
  const MyCommentsScreen({super.key});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getMyComments();
      if (mounted) {
        setState(() {
          _comments = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내가 쓴 댓글')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _comments.isEmpty
              ? const Center(child: Text('작성한 댓글이 없습니다'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      final postData = c['posts'] as Map<String, dynamic>?;
                      final postTitle = postData?['title'] as String? ?? '';
                      final postId = postData?['id'] as String?;
                      final content = c['content'] as String? ?? '';
                      final createdAt = DateTime.parse(c['created_at'] as String);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(
                            content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  postTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                              Text(
                                timeago.format(createdAt, locale: 'ko'),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          onTap: postId != null
                              ? () => context.push('/post/$postId')
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
