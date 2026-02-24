import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/widgets/banner_ad_widget.dart';
import 'package:gongter/widgets/post_card.dart';
import 'package:gongter/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTag;
  String? _municipalityId;
  String? _municipalityName;
  List<Post> _localPosts = [];
  List<Post> _hotPosts = [];
  bool _loadingLocal = true;
  bool _loadingHot = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _municipalityId = profile['municipality_id'] as String?;
        _municipalityName =
            (profile['municipalities'] as Map?)?['name'] as String?;
      });
      _loadLocalFeed();
    }
    _loadHotFeed();
  }

  Future<void> _loadLocalFeed() async {
    if (_municipalityId == null) {
      // Cold start: show national latest
      setState(() => _loadingLocal = true);
      try {
        final data = await SupabaseService.getLatestPosts();
        if (mounted) {
          setState(() {
            _localPosts = data.map((e) => Post.fromJson(e)).toList();
            _loadingLocal = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _loadingLocal = false);
      }
      return;
    }
    setState(() => _loadingLocal = true);
    try {
      final data = await SupabaseService.getFeed(
        municipalityId: _municipalityId!,
        tag: _selectedTag,
      );
      if (mounted) {
        setState(() {
          _localPosts = data.map((e) => Post.fromJson(e)).toList();
          _loadingLocal = false;
        });
        // Cold start fallback
        if (_localPosts.isEmpty && _selectedTag == null) {
          final latest = await SupabaseService.getLatestPosts();
          if (mounted) {
            setState(() {
              _localPosts = latest.map((e) => Post.fromJson(e)).toList();
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadingLocal = false);
    }
  }

  Future<void> _loadHotFeed() async {
    setState(() => _loadingHot = true);
    try {
      final data = await SupabaseService.getHotPosts();
      if (mounted) {
        setState(() {
          _hotPosts = data.map((e) => Post.fromJson(e)).toList();
          _loadingHot = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingHot = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_municipalityName ?? '공터'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '내 지자체'),
            Tab(text: '전국 HOT'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLocalTab(),
                _buildHotTab(),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/write'),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildLocalTab() {
    return Column(
      children: [
        // Tag filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildTagChip(null, '전체'),
              for (final tag in PostTag.values)
                _buildTagChip(tag.value, tag.label),
            ],
          ),
        ),
        // Post list
        Expanded(
          child: _loadingLocal
              ? const Center(child: CircularProgressIndicator())
              : _localPosts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadLocalFeed,
                      child: ListView.builder(
                        itemCount: _localPosts.length,
                        itemBuilder: (context, index) {
                          return PostCard(
                            post: _localPosts[index],
                            onTap: () =>
                                context.push('/post/${_localPosts[index].id}'),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHotTab() {
    return _loadingHot
        ? const Center(child: CircularProgressIndicator())
        : _hotPosts.isEmpty
            ? const Center(child: Text('아직 인기글이 없습니다'))
            : RefreshIndicator(
                onRefresh: _loadHotFeed,
                child: ListView.builder(
                  itemCount: _hotPosts.length,
                  itemBuilder: (context, index) {
                    return PostCard(
                      post: _hotPosts[index],
                      showMunicipality: true,
                      onTap: () =>
                          context.push('/post/${_hotPosts[index].id}'),
                    );
                  },
                ),
              );
  }

  Widget _buildTagChip(String? tagValue, String label) {
    final selected = _selectedTag == tagValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(label),
        onSelected: (val) {
          setState(() => _selectedTag = val ? tagValue : null);
          _loadLocalFeed();
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '아직 글이 없습니다',
            style: TextStyle(
                fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => context.push('/write'),
            icon: const Icon(Icons.edit),
            label: const Text('첫 글을 작성해보세요'),
          ),
        ],
      ),
    );
  }
}
