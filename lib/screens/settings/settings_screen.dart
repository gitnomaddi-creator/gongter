import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/municipality.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAdmin = false;
  String? _currentMunicipalityName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _isAdmin = profile['role'] == 'admin';
        _currentMunicipalityName =
            (profile['municipalities'] as Map<String, dynamic>?)?['full_name'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          if (_isAdmin) ...[
            const _SectionHeader('관리자'),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('지자체 변경'),
              subtitle: Text(_currentMunicipalityName ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangeMunicipality(context),
            ),
            const Divider(),
          ],
          const _SectionHeader('일반'),
          const ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('다크 모드'),
            subtitle: Text('시스템 설정을 따릅니다'),
          ),
          const Divider(),
          const _SectionHeader('법적 고지'),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('공무원법 주의사항'),
            onTap: () => _showLegalNotice(context),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('이용약관'),
            onTap: () => _openUrl('https://gitnomaddi-creator.github.io/gongter/terms.html'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('개인정보처리방침'),
            onTap: () => _openUrl('https://gitnomaddi-creator.github.io/gongter/privacy.html'),
          ),
          const Divider(),
          const _SectionHeader('문의'),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('고객 문의'),
            subtitle: const Text('nomad.webapp@gmail.com'),
            onTap: () async {
              final uri = Uri.parse('mailto:nomad.webapp@gmail.com');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          const Divider(),
          const _SectionHeader('사용자 관리'),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('차단 목록'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _BlockedUsersScreen()),
            ),
          ),
          const Divider(),
          const _SectionHeader('계정'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () async {
              await SupabaseService.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('계정 삭제',
                style: TextStyle(color: AppColors.error)),
            subtitle: const Text('글과 댓글은 익명화되어 유지됩니다'),
            onTap: () => _showDeleteConfirm(context),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showChangeMunicipality(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _ChangeMunicipalityScreen()),
    ).then((_) => _loadProfile());
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLegalNotice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공무원법 주의사항'),
        content: const Text(AppConstants.legalNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '정말 계정을 삭제하시겠습니까?\n\n'
          '- 작성한 글과 댓글은 "탈퇴한 사용자"로 익명화됩니다\n'
          '- 프로필과 인증 정보만 삭제됩니다\n'
          '- 이 작업은 되돌릴 수 없습니다',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteAccount();
              if (context.mounted) context.go('/login');
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 지자체 변경 화면 (admin only)
// ============================================================
class _ChangeMunicipalityScreen extends StatefulWidget {
  const _ChangeMunicipalityScreen();

  @override
  State<_ChangeMunicipalityScreen> createState() => _ChangeMunicipalityScreenState();
}

class _ChangeMunicipalityScreenState extends State<_ChangeMunicipalityScreen> {
  List<Municipality> _metros = [];
  List<Municipality> _basics = [];
  Municipality? _selectedMetro;
  Municipality? _selectedBasic;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMetros();
  }

  Future<void> _loadMetros() async {
    final data = await SupabaseService.getMunicipalities(level: 1);
    if (mounted) {
      setState(() {
        _metros = data.map((e) => Municipality.fromJson(e)).toList();
      });
    }
  }

  Future<void> _loadBasics(String metroId) async {
    final data = await SupabaseService.getMunicipalities(level: 2, parentId: metroId);
    if (mounted) {
      setState(() {
        _basics = data.map((e) => Municipality.fromJson(e)).toList();
      });
    }
  }

  Future<void> _save() async {
    final id = _selectedBasic?.id ?? _selectedMetro?.id;
    if (id == null) return;

    setState(() => _saving = true);
    try {
      await SupabaseService.client.rpc('change_municipality', params: {
        'p_municipality_id': id,
      });
      await SupabaseService.checkProfileComplete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지자체가 변경되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('변경에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지자체 변경')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Municipality>(
              initialValue: _selectedMetro,
              decoration: const InputDecoration(
                labelText: '시/도',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _metros
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (metro) {
                setState(() {
                  _selectedMetro = metro;
                  _selectedBasic = null;
                  _basics = [];
                });
                if (metro != null) _loadBasics(metro.id);
              },
            ),
            const SizedBox(height: 16),
            if (_selectedMetro != null && _basics.isNotEmpty)
              DropdownButtonFormField<Municipality>(
                initialValue: _selectedBasic,
                decoration: const InputDecoration(
                  labelText: '시/군/구',
                  prefixIcon: Icon(Icons.apartment),
                ),
                items: _basics
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                    .toList(),
                onChanged: (basic) => setState(() => _selectedBasic = basic),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving || _selectedMetro == null ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('변경하기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 차단 목록 화면
// ============================================================
class _BlockedUsersScreen extends StatefulWidget {
  const _BlockedUsersScreen();

  @override
  State<_BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<_BlockedUsersScreen> {
  List<Map<String, dynamic>> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getBlockedUsers();
      if (mounted) setState(() { _blocked = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(String blockedId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('차단 해제'),
        content: const Text('이 사용자의 차단을 해제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('해제')),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.unblockUser(blockedId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('차단 목록')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? const Center(child: Text('차단한 사용자가 없습니다'))
              : ListView.builder(
                  itemCount: _blocked.length,
                  itemBuilder: (context, index) {
                    final item = _blocked[index];
                    final nickname = (item['profiles'] as Map?)?['nickname'] ?? '알 수 없음';
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(nickname as String),
                      trailing: TextButton(
                        onPressed: () => _unblock(item['blocked_id'] as String),
                        child: const Text('차단 해제',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
