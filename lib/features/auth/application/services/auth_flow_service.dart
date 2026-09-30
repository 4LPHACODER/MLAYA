import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_session_info.dart';
import '../requests/get_access_token_request.dart';
import '../requests/get_current_user_request.dart';
import '../requests/get_current_session_request.dart';
import '../requests/refresh_session_request.dart';
import '../requests/sign_in_request.dart';
import '../requests/sign_in_with_google_request.dart';
import '../requests/sign_out_request.dart';
import '../requests/sign_up_request.dart';
import '../usecases/get_access_token_usecase.dart';
import '../usecases/get_current_user_usecase.dart';
import '../usecases/get_current_session_usecase.dart';
import '../usecases/refresh_session_usecase.dart';
import '../usecases/sign_in_usecase.dart';
import '../usecases/sign_in_with_google_usecase.dart';
import '../usecases/sign_out_usecase.dart';
import '../usecases/sign_up_usecase.dart';

class AuthFlowService {
  final SignInUsecase _signInUsecase;
  final SignUpUsecase _signUpUsecase;
  final SignInWithGoogleUsecase _signInWithGoogleUsecase;
  final SignOutUsecase _signOutUsecase;
  final GetCurrentUserUsecase _getCurrentUserUsecase;
  final GetCurrentSessionUsecase _getCurrentSessionUsecase;
  final GetAccessTokenUsecase _getAccessTokenUsecase;
  final RefreshSessionUsecase _refreshSessionUsecase;

  AuthFlowService(
    this._signInUsecase,
    this._signUpUsecase,
    this._signInWithGoogleUsecase,
    this._signOutUsecase,
    this._getCurrentUserUsecase,
    this._getCurrentSessionUsecase,
    this._getAccessTokenUsecase,
    this._refreshSessionUsecase,
  );

  Future<AppUser?> getCurrentUser() async {
    return await _getCurrentUserUsecase(const GetCurrentUserRequest());
  }

  Future<AppUser> signIn(String email, String password) async {
    return await _signInUsecase(SignInRequest(email: email, password: password));
  }

  Future<AppUser> signUp(String email, String password) async {
    return await _signUpUsecase(SignUpRequest(email: email, password: password));
  }

  Future<AppUser> signInWithGoogle() async {
    return await _signInWithGoogleUsecase(const SignInWithGoogleRequest());
  }

  Future<void> signOut() async {
    await _signOutUsecase(const SignOutRequest());
  }

  Future<AuthSessionInfo?> getCurrentSession({bool forceRefresh = false}) async {
    return await _getCurrentSessionUsecase(GetCurrentSessionRequest(forceRefresh: forceRefresh));
  }

  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    return await _getAccessTokenUsecase(GetAccessTokenRequest(forceRefresh: forceRefresh));
  }

  Future<AuthSessionInfo?> refreshSession() async {
    return await _refreshSessionUsecase(const RefreshSessionRequest());
  }
}