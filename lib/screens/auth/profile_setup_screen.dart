import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gongter/models/municipality.dart';
import 'package:gongter/services/supabase_service.dart';
import 'package:gongter/theme/app_theme.dart';
import 'package:gongter/utils/constants.dart';

/// Shown when a logged-in user has no municipality set (incomplete profile).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  List<Municipality> _metros = [];
  List<Municipality> _basics = [];
  Municipality? _selectedMetro;
  Municipality? _selectedMunicipality;
  bool _loading = true;
  String? _error;

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

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.length < AppConstants.minNicknameLength) {
      setState(() => _error = '닉네임은 ${AppConstants.minNicknameLength}자 이상이어야 합니다');
      return;
    }
    final nicknameError = await SupabaseService.validateNickname(nickname);
    if (nicknameError != null) {
      setState(() => _error = nicknameError);
      return;
    }
    final municipalityId =
        _selectedMunicipality?.id ?? _selectedMetro?.id;
    if (municipalityId == null) {
      setState(() => _error = '소속 지자체를 선택해주세요');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await SupabaseService.completeProfileSetup(
        municipalityId: municipalityId,
        nickname: nickname,
        verificationMethod: 'email',
      );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = '프로필 설정에 실패했습니다');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 설정'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) context.go('/login');
            },
            child:
                const Text('로그아웃', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: _loading && _metros.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '소속 지자체와 닉네임을 설정하면\n공터를 이용할 수 있습니다',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nicknameController,
                    maxLength: AppConstants.maxNicknameLength,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      hintText: '2~10자 한글/영문/숫자',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('시작하기',
                            style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
