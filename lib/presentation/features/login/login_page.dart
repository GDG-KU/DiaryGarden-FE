import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasource/auth_api_client.dart';
import '../../../data/models/auth_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _authApiClient = AuthApiClient();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restoreToken();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _restoreToken() async {
    final stored = await TokenStorage.readToken();
    if (stored != null && stored.isNotEmpty && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (username.isEmpty || password.isEmpty || (_isRegisterMode && displayName.isEmpty)) {
      setState(() => _errorMessage = '필수 항목을 모두 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AuthSession session;
      if (_isRegisterMode) {
        session = await _authApiClient.register(
          username: username,
          password: password,
          displayName: displayName,
        );
      } else {
        session = await _authApiClient.login(
          username: username,
          password: password,
        );
      }

      if (session.token.isEmpty) {
        throw const AuthApiException('토큰이 응답에 없습니다. Firebase 로그인 토큰이 필요합니다.');
      }

      await TokenStorage.saveToken(session.token);
      await TokenStorage.saveUser(
        username: session.username.isNotEmpty ? session.username : username,
        displayName: session.displayName.isNotEmpty ? session.displayName : displayName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isRegisterMode ? '회원가입 완료! 🌱' : '로그인 성공!'),
          backgroundColor: AppColors.leafGreen,
          duration: const Duration(milliseconds: 1500),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error is AuthApiException
            ? error.message
            : (error is TimeoutException
                ? '서버 응답이 지연됩니다. 잠시 후 다시 시도해주세요.'
                : '요청에 실패했습니다. 다시 시도해주세요.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Diary Garden',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              _isRegisterMode ? '회원가입' : '로그인',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _LabeledField(
              label: '아이디',
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: '4~20자 영문/숫자/언더스코어',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: '비밀번호',
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '6자 이상 비밀번호',
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isRegisterMode)
              _LabeledField(
                label: '표시 이름',
                child: TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    hintText: '앱에 표시될 이름',
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.leafCoral),
                ),
              ),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.trunk,
                  foregroundColor: AppColors.textOnTrunk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnTrunk,
                        ),
                      )
                    : Text(_isRegisterMode ? '회원가입' : '로그인'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _errorMessage = null;
                      });
                    },
              child: Text(
                _isRegisterMode ? '이미 계정이 있어요. 로그인' : '새 계정 만들기',
                style: const TextStyle(color: AppColors.trunk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
        ),
      ],
    );
  }
}
