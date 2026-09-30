import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/auth_providers.dart';
import '../../application/services/auth_flow_service.dart';
import '../../domain/entities/auth_session_info.dart';
import '../states/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthFlowService _authFlowService;

  AuthController._(this._authFlowService) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> _executeOperation<T>({
    required Future<T> Function() operation,
    required void Function(T) onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await operation();
      state = state.copyWith(isLoading: false);
      onSuccess(result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> checkAuthStatus() async {
    await _executeOperation(
      operation: () => _authFlowService.getCurrentUser(),
      onSuccess: (user) => state = state.copyWith(user: user),
    );
  }

  Future<void> signIn(String email, String password) async {
    await _executeOperation(
      operation: () => _authFlowService.signIn(email, password),
      onSuccess: (user) => state = state.copyWith(user: user),
    );
  }

  Future<void> signUp(String email, String password) async {
    await _executeOperation(
      operation: () => _authFlowService.signUp(email, password),
      onSuccess: (user) => state = state.copyWith(user: user),
    );
  }

  Future<void> signInWithGoogle() async {
    await _executeOperation(
      operation: () => _authFlowService.signInWithGoogle(),
      onSuccess: (user) => state = state.copyWith(user: user),
    );
  }

  Future<void> signOut() async {
    await _executeOperation(
      operation: () => _authFlowService.signOut(),
      onSuccess: (_) => state = state.copyWith(user: null),
    );
  }

  /// Debug/testing helper for manual Postman workflows.
  /// Do not auto-display this token in normal UI flows.
  Future<String?> getAccessTokenForDebug({bool forceRefresh = false}) async {
    return await _authFlowService.getAccessToken(forceRefresh: forceRefresh);
  }

  /// Returns session metadata for diagnostics without altering login UI behavior.
  Future<AuthSessionInfo?> getCurrentSessionForDebug({
    bool forceRefresh = false,
  }) async {
    return await _authFlowService.getCurrentSession(forceRefresh: forceRefresh);
  }

  Future<AuthSessionInfo?> refreshSessionForDebug() async {
    return await _authFlowService.refreshSession();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authFlowService = ref.watch(authFlowServiceProvider);
    return AuthController._(authFlowService);
  },
);