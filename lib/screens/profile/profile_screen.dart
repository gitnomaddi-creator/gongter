import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getProfile();
      if (mounted) {
        setState(() {
          _profile = data;
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
      appBar: AppBar(
        title: const Text('마이'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('프로필을 불러올 수 없습니다'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Profile card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.person,
                                  size: 40, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _profile!['nickname'] as String? ?? '닉네임 미설정',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (_profile!['municipalities']
                                      as Map?)?['full_name'] as String? ??
                                  '소속 미설정',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_profile!['is_verified'] == true)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        size: 16, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text('인증 완료',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primary)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Menu items
                    _buildMenuItem(Icons.article_outlined, '내가 쓴 글', () {
                      // TODO
                    }),
                    _buildMenuItem(Icons.chat_outlined, '내가 쓴 댓글', () {
                      // TODO
                    }),
                    _buildMenuItem(Icons.bookmark_outline, '북마크', () {
                      // TODO
                    }),
                    _buildMenuItem(Icons.edit_outlined, '닉네임 변경', () {
                      _showNicknameDialog();
                    }),
                  ],
                ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _showNicknameDialog() {
    final controller =
        TextEditingController(text: _profile?['nickname'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          maxLength: 10,
          decoration: const InputDecoration(
            hintText: '2~10자 한글/영문/숫자',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nickname = controller.text.trim();
              if (nickname.length >= 2) {
                await SupabaseService.updateProfile(nickname: nickname);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadProfile();
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
