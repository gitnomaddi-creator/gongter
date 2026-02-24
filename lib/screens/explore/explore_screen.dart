import 'package:flutter/material.dart';
import 'package:gongter/models/municipality.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Municipality> _metros = [];
  List<Municipality> _basics = [];
  String? _selectedMetroId;
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMetros();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('탐색')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '지자체 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Metro list or basics list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedMetroId == null
                    ? _buildMetroList()
                    : _buildBasicList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetroList() {
    final query = _searchController.text.trim().toLowerCase();
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
    final query = _searchController.text.trim().toLowerCase();
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
                  // TODO: Navigate to municipality feed
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
