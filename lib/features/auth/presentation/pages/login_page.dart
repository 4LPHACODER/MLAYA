import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/email_input_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_input_field.dart';
import '../widgets/auth_ui_shell.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final isValid = _formKey.currentState!.validate();
    // #region agent log
    _debugLog(
      runId: 'run-pre-fix',
      hypothesisId: 'H4',
      location: 'login_page.dart:_signIn',
      message: 'SignIn validation result',
      data: {'isValid': isValid},
    );
    // #endregion
    if (!isValid) return;
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  Future<void> _signInWithGoogle() async {
    final controller = ref.read(authControllerProvider.notifier);
    await controller.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final compact = MediaQuery.of(context).size.width < 360;

    ref.listen<AuthState?>(authControllerProvider, (previous, next) {
      if (next == null) return;
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    return AuthNatureScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthBrandHeader(subtitle: 'Escape into Nature'),
            SizedBox(height: compact ? 24 : 32),
            _buildAuthCard(context, authState),
            const SizedBox(height: 18),
            _buildSignUpLink(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, AuthState authState) {
    final compact = MediaQuery.of(context).size.width < 360;

    return AuthGlassCard(
      child: Column(
        children: [
          Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: compact ? 25 : 30,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334638),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to access weather forecasts and explore your day.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF677D6E),
              height: 1.45,
              fontSize: compact ? 13 : 14,
            ),
          ),
          const SizedBox(height: 26),
          EmailInputField(controller: _emailController),
          const SizedBox(height: 14),
          PasswordInputField(controller: _passwordController),
          const SizedBox(height: 20),
          AuthButton(
            text: 'Sign In',
            onPressed: authState.isLoading ? null : _signIn,
            isLoading: authState.isLoading,
          ),
          const SizedBox(height: 18),
          const AuthSectionDivider(),
          const SizedBox(height: 18),
          GoogleSignInButton(
            onPressed: authState.isLoading ? null : _signInWithGoogle,
            isLoading: authState.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () {
            // #region agent log
            _debugLog(
              runId: 'run-post-fix',
              hypothesisId: 'H2',
              location: 'login_page.dart:_buildSignUpLink:onTap',
              message: 'SignUp tap invoked',
              data: {
                'emailLength': _emailController.text.trim().length,
                'passwordLength': _passwordController.text.trim().length,
              },
            );
            // #endregion
            // #region agent log
            _debugLog(
              runId: 'run-post-fix',
              hypothesisId: 'H3',
              location: 'login_page.dart:_buildSignUpLink:onTap',
              message: 'Attempting Navigator.push to SignupPage',
              data: const {
                'route': 'SignupPage',
                'validationGateRemoved': true,
              },
            );
            // #endregion
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupPage()),
            );
          },
          child: Text(
            'Sign Up',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF3E5E4C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _debugLog({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, Object?> data,
  }) async {
    final payload = <String, Object?>{
      'sessionId': '741a77',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    // #region agent log
    debugPrint('AGENT_DEBUG_741a77 ${payload.toString()}');
    // #endregion
    try {
      await Dio().post(
        'http://127.0.0.1:7881/ingest/dd55a01c-8673-4314-ab47-4b7bcf85eab6',
        data: payload,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': '741a77',
          },
        ),
      );
    } catch (_) {}
  }
}
