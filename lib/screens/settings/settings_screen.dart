import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _SectionHeader('일반'),
          // Dark mode is handled by system, show info
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
