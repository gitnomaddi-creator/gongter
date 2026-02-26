import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/municipality.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 0: email/password + terms, 1: OTP, 2: profile setup
  int _step = 0;

  // Auth fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nicknameController = TextEditingController();

  // Municipality selection
  List<Municipality> _metros = [];
  List<Municipality> _basics = [];
  Municipality? _selectedMetro;
  Municipality? _selectedMunicipality;
  Municipality? _autoDetectedMunicipality;

  // Terms agreement
  bool _agreedToTerms = false;

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return '회원가입';
      case 1:
        return '인증코드 입력';
      case 2:
        return '프로필 설정';
      default:
        return '회원가입';
    }
  }

  void _goBack() {
    setState(() => _error = null);
    if (_step == 0) {
      context.pop();
    } else if (_step == 2) {
      // Can't go back from profile setup after OTP verified
      context.pop();
    } else {
      setState(() => _step = _step - 1);
    }
  }

  // Step 0: Sign up with email + password
  Future<void> _submitSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력해주세요');
      return;
    }

    if (!email.endsWith('.go.kr')) {
      setState(() => _error = '*.go.kr 이메일만 사용 가능합니다');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = '비밀번호는 6자 이상이어야 합니다');
      return;
    }

    if (password != confirm) {
      setState(() => _error = '비밀번호가 일치하지 않습니다');
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _error = '이용약관 및 개인정보처리방침에 동의해주세요');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await SupabaseService.signUp(email: email, password: password);

      // Try to auto-detect municipality from email domain
      final domain = email.split('@').last;
      final muni = await SupabaseService.getMunicipalityByDomain(domain);
      if (muni != null) {
        _autoDetectedMunicipality = Municipality.fromJson(muni);
      }

      if (mounted) setState(() => _step = 1);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('already registered')) {
        setState(() => _error = '이미 등록된 이메일입니다');
      } else {
        setState(() => _error = '회원가입에 실패했습니다. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Step 1: Verify OTP
  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || code.length != 6) {
      setState(() => _error = '6자리 인증코드를 입력해주세요');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await SupabaseService.verifyOtp(
        email: _emailController.text.trim(),
        token: code,
      );

      if (mounted) {
        await _loadMetros();
        setState(() => _step = 2);
      }
    } catch (e) {
      setState(() => _error = '인증코드가 올바르지 않습니다');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await SupabaseService.resendOtp(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증코드를 다시 발송했습니다')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('잠시 후 다시 시도해주세요')),
        );
      }
    }
  }

  // Municipality loading
  Future<void> _loadMetros() async {
    final data = await SupabaseService.getMunicipalities(level: 1);
    _metros = data.map((e) => Municipality.fromJson(e)).toList();
  }

  Future<void> _loadBasics(String metroId) async {
    setState(() => _loading = true);
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

  // Step 2: Complete profile setup
  Future<void> _completeSetup() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 10) {
      setState(() => _error = '닉네임은 2~10자로 입력해주세요');
      return;
    }
    final nicknameRegex = RegExp(r'^[가-힣a-zA-Z0-9]+$');
    if (!nicknameRegex.hasMatch(nickname)) {
      setState(() => _error = '닉네임은 한글, 영문, 숫자만 사용 가능합니다');
      return;
    }

    final municipalityId =
        _selectedMunicipality?.id ?? _autoDetectedMunicipality?.id;
    // For 세종시 (no 기초), use the metro itself
    final finalMunicipalityId = municipalityId ?? _selectedMetro?.id;

    if (finalMunicipalityId == null) {
      setState(() => _error = '소속 지자체를 선택해주세요');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await SupabaseService.completeProfileSetup(
        municipalityId: finalMunicipalityId,
        nickname: nickname,
        verificationMethod: 'email',
        verifiedEmail: _emailController.text.trim(),
      );

      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = '프로필 설정에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: switch (_step) {
          0 => _buildEmailPassword(),
          1 => _buildOtpVerification(),
          2 => _buildProfileSetup(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  // ─── Step 0: Email + Password + Terms ───
  Widget _buildEmailPassword() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '공무원 이메일(*.go.kr)을 입력해주세요.\n이메일로 6자리 인증코드가 발송됩니다.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: 'name@korea.kr',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: '6자 이상',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: '비밀번호 확인',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legal notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      '공무원법 주의사항',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• 직무상 비밀 누설 금지 (제60조)\n'
                  '• 품위유지 의무 (제63조)\n'
                  '• 정치 중립 의무 (제65조)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '본 앱의 게시글은 개인 의견이며,\n법적 책임은 작성자 본인에게 있습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Terms agreement
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (val) =>
                      setState(() => _agreedToTerms = val ?? false),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _agreedToTerms = !_agreedToTerms),
                  child: const Text(
                    '이용약관 및 개인정보처리방침에 동의합니다',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () => _openUrl(
                    'https://gitnomaddi-creator.github.io/gongter/terms.html'),
                child: const Text(
                  '이용약관',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _openUrl(
                    'https://gitnomaddi-creator.github.io/gongter/privacy.html'),
                child: const Text(
                  '개인정보처리방침',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submitSignup,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('인증코드 발송', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: OTP Verification ───
  Widget _buildOtpVerification() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            '${_emailController.text.trim()}(으)로\n인증코드를 발송했습니다',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            '스팸 메일함도 확인해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('인증 확인', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resendOtp,
            child: const Text('인증코드 재발송'),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Profile Setup ───
  Widget _buildProfileSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '소속 지자체와 닉네임을 설정해주세요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // Auto-detected municipality
          if (_autoDetectedMunicipality != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('이메일에서 자동 감지됨',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text(
                          _autoDetectedMunicipality!.fullName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _autoDetectedMunicipality = null),
                    child: const Text('변경'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Manual municipality selection
          if (_autoDetectedMunicipality == null) ...[
            const Text('소속 지자체',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Metro dropdown
            DropdownButtonFormField<Municipality>(
              initialValue: _selectedMetro,
              decoration: const InputDecoration(
                labelText: '시/도',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: _metros
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name),
                      ))
                  .toList(),
              onChanged: (metro) {
                setState(() {
                  _selectedMetro = metro;
                  _selectedMunicipality = null;
                  _basics = [];
                });
                if (metro != null) _loadBasics(metro.id);
              },
            ),
            const SizedBox(height: 12),

            // Basic dropdown (if applicable)
            if (_selectedMetro != null && _basics.isNotEmpty)
              DropdownButtonFormField<Municipality>(
                initialValue: _selectedMunicipality,
                decoration: const InputDecoration(
                  labelText: '시/군/구',
                  prefixIcon: Icon(Icons.apartment),
                ),
                items: _basics
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (basic) =>
                    setState(() => _selectedMunicipality = basic),
              ),

            if (_selectedMetro != null &&
                _basics.isEmpty &&
                !_loading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_selectedMetro!.name}이(가) 소속으로 설정됩니다',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // Nickname
          const Text('닉네임', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            maxLength: AppConstants.maxNicknameLength,
            decoration: const InputDecoration(
              hintText: '2~10자 한글/영문/숫자',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _completeSetup,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('시작하기', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
