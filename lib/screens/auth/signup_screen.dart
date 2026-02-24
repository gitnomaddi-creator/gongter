import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0; // 0: method selection, 1: email auth, 2: document auth

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step = 0);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: _step == 0
            ? _buildMethodSelection()
            : _step == 1
                ? _buildEmailAuth()
                : _buildDocumentAuth(),
      ),
    );
  }

  Widget _buildMethodSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            '인증 방법을 선택하세요',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '공무원 재직 확인을 위해 인증이 필요합니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          // Legal notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              AppConstants.legalNotice,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          // Option 1: Email
          _buildOptionCard(
            icon: Icons.email,
            title: '공무원 이메일 인증',
            subtitle: '*.go.kr 이메일로 인증코드 발송',
            onTap: () => setState(() => _step = 1),
          ),
          const SizedBox(height: 16),
          // Option 2: Document
          _buildOptionCard(
            icon: Icons.description,
            title: '재직증명서 인증',
            subtitle: '재직증명서 사진 촬영/업로드 (1~2일 내 승인)',
            onTap: () => setState(() => _step = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailAuth() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: Text('이메일 인증 화면 (구현 예정)')),
    );
  }

  Widget _buildDocumentAuth() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: Text('재직증명서 인증 화면 (구현 예정)')),
    );
  }
}
