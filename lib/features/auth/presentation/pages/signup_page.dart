import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/email_input_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_input_field.dart';
import '../widgets/auth_input_decoration.dart';
import '../widgets/auth_ui_shell.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  @override
  void initState() {
    super.initState();
    // #region agent log
    _debugLog(
      runId: 'run-post-fix',
      hypothesisId: 'H3',
      location: 'signup_page.dart:initState',
      message: 'SignupPage reached',
      data: const {'arrived': true},
    );
    // #endregion
  }

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    await controller.signUp(
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

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user == null && next.user != null) {
        // Return to root so AuthGate can render WeatherMapPage.
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return AuthNatureScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthBrandHeader(subtitle: 'Create your account'),
            SizedBox(height: compact ? 24 : 32),
            _buildSignUpCard(context, authState),
            const SizedBox(height: 18),
            _buildSignInLink(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpCard(BuildContext context, AuthState authState) {
    final compact = MediaQuery.of(context).size.width < 360;
    return AuthGlassCard(
      child: Column(
        children: [
          Text(
            'Start Your Journey',
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
            'Create an account to save places and personalize your weather experience.',
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
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: buildAuthInputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter your password',
              prefixIcon: Icons.lock_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthButton(
            text: 'Sign Up',
            onPressed: authState.isLoading ? null : _signUp,
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

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Sign In',
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
