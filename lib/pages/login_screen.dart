import 'dart:async';

import 'package:flutter/material.dart';
import 'package:start_on/repositories/auth_repository.dart';
import 'package:start_on/services/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.onSignIn,
    required this.onSignUp,
    required this.onGuestStart,
    super.key,
  });

  final Future<void> Function({required String email, required String password})
  onSignIn;
  final Future<void> Function({required String email, required String password})
  onSignUp;
  final Future<void> Function() onGuestStart;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  _AuthMode _mode = _AuthMode.signIn;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8EF), Color(0xFFF6FAFF), Color(0xFFFFF0F3)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        const _LoginHero(),
                        const SizedBox(height: 34),
                        _LoginFormCard(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          isPasswordVisible: _isPasswordVisible,
                          isSubmitting: _isSubmitting,
                          mode: _mode,
                          errorMessage: _errorMessage,
                          onModeChanged: _handleModeChanged,
                          onPasswordVisibilityToggle: () {
                            setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            );
                          },
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: 18),
                        _GuestStartButton(
                          isEnabled: !_isSubmitting,
                          onPressed: _startAsGuest,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      switch (_mode) {
        case _AuthMode.signIn:
          await widget.onSignIn(email: email, password: password);
        case _AuthMode.signUp:
          await widget.onSignUp(email: email, password: password);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _loginErrorMessage(error));
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
  }

  Future<void> _startAsGuest() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onGuestStart();
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _loginErrorMessage(error));
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
  }

  void _handleModeChanged(_AuthMode mode) {
    if (_isSubmitting || mode == _mode) {
      return;
    }

    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  String _loginErrorMessage(Object error) {
    if (error is ApiClientException) {
      if (error.code == 'supabase_auth_failed') {
        return _mode == _AuthMode.signUp
            ? '이미 가입된 이메일이거나 가입 정보를 확인할 수 없어요.'
            : '이메일 또는 비밀번호를 확인해 주세요.';
      }
      if (error.code == 'signup_requires_confirmation') {
        return '가입은 접수됐지만 이메일 확인이 필요해요. 메일 확인 후 로그인해 주세요.';
      }
      if (error.code == 'supabase_auth_network_error') {
        return '인증 서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.';
      }
      return error.message;
    }

    if (error is AuthRepositoryException) {
      return error.message;
    }

    if (error is TimeoutException) {
      return '서버 응답 시간이 초과됐어요. 잠시 후 다시 시도해 주세요.';
    }

    return '로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';
  }
}

enum _AuthMode { signIn, signUp }

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF1C2940),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8F9DB6).withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Color(0xFFF6B42D),
            size: 34,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'START ON',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF07080A),
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '오늘도 시작해 볼까요?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF33415C),
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isSubmitting,
    required this.mode,
    required this.errorMessage,
    required this.onModeChanged,
    required this.onPasswordVisibilityToggle,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isSubmitting;
  final _AuthMode mode;
  final String? errorMessage;
  final ValueChanged<_AuthMode> onModeChanged;
  final VoidCallback onPasswordVisibilityToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isSignUp = mode == _AuthMode.signUp;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8C7DE).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isSignUp ? '회원가입' : '로그인',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1C2940),
                      ),
                    ),
                  ),
                  SegmentedButton<_AuthMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment<_AuthMode>(
                        value: _AuthMode.signIn,
                        label: Text('로그인'),
                      ),
                      ButtonSegment<_AuthMode>(
                        value: _AuthMode.signUp,
                        label: Text('가입'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: isSubmitting
                        ? null
                        : (selected) => onModeChanged(selected.single),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isSignUp) ...[
                const SizedBox(height: 10),
                const Text(
                  '가입 후 바로 시작할 수 있어요.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF526079),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _AuthTextField(
                controller: emailController,
                label: '이메일',
                hintText: 'name@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const SizedBox(height: 14),
              _AuthTextField(
                controller: passwordController,
                label: '비밀번호',
                hintText: '비밀번호 입력',
                icon: Icons.lock_outline_rounded,
                obscureText: !isPasswordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) => _validatePassword(value, mode),
                onFieldSubmitted: (_) {
                  if (!isSubmitting) {
                    onSubmit();
                  }
                },
                suffixIcon: IconButton(
                  tooltip: isPasswordVisible ? '비밀번호 숨기기' : '비밀번호 보기',
                  onPressed: onPasswordVisibilityToggle,
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 14),
                _LoginErrorBanner(message: errorMessage!),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isSubmitting
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isSignUp
                              ? Icons.person_add_alt_1_rounded
                              : Icons.login_rounded,
                          key: ValueKey(mode),
                        ),
                ),
                label: Text(
                  isSubmitting
                      ? (isSignUp ? '가입 중' : '로그인 중')
                      : (isSignUp ? '회원가입' : '로그인'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6F63FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB9B5FF),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return '이메일 형식으로 입력해 주세요.';
    }
    return null;
  }

  String? _validatePassword(String? value, _AuthMode mode) {
    final minLength = mode == _AuthMode.signUp ? 6 : 4;
    if ((value ?? '').length < minLength) {
      return '비밀번호는 $minLength자 이상 입력해 주세요.';
    }
    return null;
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC9CE)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFC33D4A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF80313A),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: Color(0xFF1C2940),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6ECF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6F63FF), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF8B93), width: 1.2),
        ),
      ),
    );
  }
}

class _GuestStartButton extends StatelessWidget {
  const _GuestStartButton({required this.isEnabled, required this.onPressed});

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: const Icon(Icons.person_outline_rounded),
      label: const Text('게스트로 시작'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF526079),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
  }
}
