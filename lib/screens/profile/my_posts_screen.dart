import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/widgets/post_card.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
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
      final data = await SupabaseService.getMyPosts();
      if (mounted) {
        setState(() {
          _posts = data.map((e) => Post.fromJson(e)).toList();
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
      appBar: AppBar(title: const Text('내가 쓴 글')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('작성한 글이 없습니다'))
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
