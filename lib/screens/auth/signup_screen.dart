import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gongter/models/municipality.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 0: method, 1: email/password, 2: OTP, 3: document upload, 4: profile setup
  int _step = 0;
  String _method = ''; // 'email' or 'document'

  // Auth fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nicknameController = TextEditingController();

  // Document
  File? _docFile;

  // Municipality selection
  List<Municipality> _metros = [];
  List<Municipality> _basics = [];
  Municipality? _selectedMetro;
  Municipality? _selectedMunicipality;
  Municipality? _autoDetectedMunicipality;

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
        return _method == 'email' ? '이메일 인증' : '계정 생성';
      case 2:
        return '인증코드 입력';
      case 3:
        return '재직증명서 제출';
      case 4:
        return '프로필 설정';
      default:
        return '회원가입';
    }
  }

  void _goBack() {
    setState(() => _error = null);
    if (_step == 0) {
      context.pop();
    } else if (_step == 4 && _method == 'document') {
      setState(() => _step = 3);
    } else if (_step == 4 && _method == 'email') {
      // Can't go back from profile setup after OTP verified
      context.pop();
    } else if (_step == 3) {
      setState(() => _step = 2);
    } else if (_step == 2) {
      setState(() => _step = 1);
    } else {
      setState(() => _step = 0);
    }
  }

  // Step 1: Sign up with email + password
  Future<void> _submitSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력해주세요');
      return;
    }

    if (_method == 'email' && !email.endsWith('.go.kr')) {
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

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await SupabaseService.signUp(email: email, password: password);

      // For email method, try to auto-detect municipality
      if (_method == 'email') {
        final domain = email.split('@').last;
        final muni = await SupabaseService.getMunicipalityByDomain(domain);
        if (muni != null) {
          _autoDetectedMunicipality = Municipality.fromJson(muni);
        }
      }

      if (mounted) setState(() => _step = 2);
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

  // Step 2: Verify OTP
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
        if (_method == 'document') {
          setState(() => _step = 3);
        } else {
          // Email method: go to profile setup
          await _loadMetros();
          setState(() => _step = 4);
        }
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

  // Step 3: Upload document
  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _docFile = File(picked.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _docFile = File(picked.path));
    }
  }

  Future<void> _submitDocument() async {
    if (_docFile == null) {
      setState(() => _error = '재직증명서 사진을 선택해주세요');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _loadMetros();
      if (mounted) setState(() => _step = 4);
    } catch (e) {
      setState(() => _error = '오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
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

  // Step 4: Complete profile setup
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
      // Upload document if document method
      if (_method == 'document' && _docFile != null) {
        final url = await SupabaseService.uploadVerificationDoc(_docFile!);
        await SupabaseService.createDocumentVerification(
          fileUrl: url,
          municipalityId: finalMunicipalityId,
        );
      }

      await SupabaseService.completeProfileSetup(
        municipalityId: finalMunicipalityId,
        nickname: nickname,
        verificationMethod: _method,
        verifiedEmail:
            _method == 'email' ? _emailController.text.trim() : null,
      );

      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = '프로필 설정에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          0 => _buildMethodSelection(),
          1 => _buildEmailPassword(),
          2 => _buildOtpVerification(),
          3 => _buildDocumentUpload(),
          4 => _buildProfileSetup(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  // ─── Step 0: Method Selection ───
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: const Text(
              AppConstants.legalNotice,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          _buildOptionCard(
            icon: Icons.email,
            title: '공무원 이메일 인증',
            subtitle: '*.go.kr 이메일로 인증코드 발송 (즉시 인증)',
            onTap: () => setState(() {
              _method = 'email';
              _step = 1;
            }),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            icon: Icons.description,
            title: '재직증명서 인증',
            subtitle: '재직증명서 사진 촬영/업로드 (1~2일 내 승인)',
            onTap: () => setState(() {
              _method = 'document';
              _step = 1;
            }),
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

  // ─── Step 1: Email + Password ───
  Widget _buildEmailPassword() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_method == 'email')
            const Text(
              '공무원 이메일(*.go.kr)을 입력해주세요.\n이메일로 6자리 인증코드가 발송됩니다.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            )
          else
            const Text(
              '로그인에 사용할 이메일과 비밀번호를 입력해주세요.\n이메일로 인증코드가 발송됩니다.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '이메일',
              hintText:
                  _method == 'email' ? 'name@city.go.kr' : 'example@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
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

  // ─── Step 2: OTP Verification ───
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

  // ─── Step 3: Document Upload ───
  Widget _buildDocumentUpload() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '재직증명서를 촬영하거나 갤러리에서 선택해주세요.\n개인정보(주민번호 등)가 가려진 상태로 제출해주세요.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_docFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_docFile!,
                  height: 300, fit: BoxFit.cover, width: double.infinity),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _docFile = null),
              icon: const Icon(Icons.close),
              label: const Text('다시 선택'),
            ),
          ] else ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDocument,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('촬영'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('갤러리'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submitDocument,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('다음', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 8),
          const Text(
            '* 심사에 1~2 영업일이 소요됩니다.\n  승인 전에도 앱 이용이 가능합니다.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Profile Setup ───
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
