import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/municipality.dart';
import 'package:gongter/models/post.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/widgets/post_card.dart';
import 'package:gongter/theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Municipality> _metros = [];
  List<Municipality> _basics = [];
  String? _selectedMetroId;
  bool _loading = true;
  final _muniSearchController = TextEditingController();

  // Post search
  final _postSearchController = TextEditingController();
  List<Post> _searchResults = [];
  bool _searching = false;
  bool _hasSearched = false;
  List<String> _blockedUserIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMetros();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    _blockedUserIds = await SupabaseService.getBlockedUserIds();
  }

  Future<void> _loadMetros() async {
    try {
      final data = await SupabaseService.getMunicipalities(level: 1);
      if (mounted) {
        setState(() {
          _metros = data.map((e) => Municipality.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBasics(String metroId) async {
    setState(() {
      _selectedMetroId = metroId;
      _loading = true;
    });
    try {
      final data =
          await SupabaseService.getMunicipalities(level: 2, parentId: metroId);
      if (mounted) {
        setState(() {
          _basics = data.map((e) => Municipality.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchPosts() async {
    final query = _postSearchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _hasSearched = true;
    });
    try {
      final data = await SupabaseService.searchPosts(query: query);
      if (mounted) {
        setState(() {
          _searchResults = data
              .map((e) => Post.fromJson(e))
              .where((p) => !_blockedUserIds.contains(p.authorId))
              .toList();
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _muniSearchController.dispose();
    _postSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('탐색'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '지자체'),
            Tab(text: '게시글 검색'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMunicipalityTab(),
          _buildPostSearchTab(),
        ],
      ),
    );
  }

  Widget _buildPostSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _postSearchController,
            decoration: InputDecoration(
              hintText: '제목 또는 내용으로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _postSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _postSearchController.clear();
                        setState(() {
                          _searchResults = [];
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchPosts(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : !_hasSearched
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('검색어를 입력해주세요',
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text('검색 결과가 없습니다',
                              style: TextStyle(color: Colors.grey.shade600)),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return PostCard(
                              post: _searchResults[index],
                              showMunicipality: true,
                              onTap: () => context.push(
                                  '/post/${_searchResults[index].id}'),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildMunicipalityTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _muniSearchController,
            decoration: InputDecoration(
              hintText: '지자체 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _muniSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _muniSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _selectedMetroId == null
                  ? _buildMetroList()
                  : _buildBasicList(),
        ),
      ],
    );
  }

  Widget _buildMetroList() {
    final query = _muniSearchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _metros
        : _metros.where((m) => m.fullName.toLowerCase().contains(query)).toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final metro = filtered[index];
        return ListTile(
          leading: const Icon(Icons.location_city, color: AppColors.primary),
          title: Text(metro.fullName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _loadBasics(metro.id),
        );
      },
    );
  }

  Widget _buildBasicList() {
    final query = _muniSearchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _basics
        : _basics.where((m) => m.fullName.toLowerCase().contains(query)).toList();
    return Column(
      children: [
        // Back to metros
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: const Text('광역시/도 목록으로'),
          onTap: () => setState(() {
            _selectedMetroId = null;
            _basics = [];
          }),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final basic = filtered[index];
              return ListTile(
                leading: const Icon(Icons.apartment,
                    color: AppColors.secondary),
                title: Text(basic.name),
                subtitle: Text(basic.fullName,
                    style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _MunicipalityFeedScreen(
                        municipalityId: basic.id,
                        municipalityName: basic.fullName,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Feed screen for a specific municipality
class _MunicipalityFeedScreen extends StatefulWidget {
  final String municipalityId;
  final String municipalityName;
  const _MunicipalityFeedScreen({
    required this.municipalityId,
    required this.municipalityName,
  });

  @override
  State<_MunicipalityFeedScreen> createState() =>
      _MunicipalityFeedScreenState();
}

class _MunicipalityFeedScreenState extends State<_MunicipalityFeedScreen> {
  List<Post> _posts = [];
  bool _loading = true;
  List<String> _blockedUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    try {
      _blockedUserIds = await SupabaseService.getBlockedUserIds();
      final data = await SupabaseService.getFeed(
        municipalityId: widget.municipalityId,
      );
      if (mounted) {
        setState(() {
          _posts = data
              .map((e) => Post.fromJson(e))
              .where((p) => !_blockedUserIds.contains(p.authorId))
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
      appBar: AppBar(title: Text(widget.municipalityName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Text('아직 글이 없습니다',
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              : RefreshIndicator(
                  onRefresh: _loadFeed,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: _posts[index],
                        onTap: () => context.push('/post/${_posts[index].id}'),
                      );
                    },
                  ),
                ),
    );
  }
}
