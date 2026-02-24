import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/widgets/post_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getMyBookmarks();
      if (mounted) {
        setState(() {
          _posts = data
              .where((b) => b['posts'] != null)
              .map((b) => Post.fromJson(b['posts'] as Map<String, dynamic>))
              .toList();
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
      appBar: AppBar(title: const Text('북마크')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('북마크한 글이 없습니다'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: _posts[index],
                        onTap: () =>
                            context.push('/post/${_posts[index].id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
