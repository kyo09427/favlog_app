import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/providers/supabase_provider.dart';
import '../../core/config/constants.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseProvider));
});

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabaseClient;

  SupabaseAuthRepository(this._supabaseClient);

  @override
  Future<AuthResponse> signUp(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    return _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: data,
      emailRedirectTo: Constants.getRedirectUrl(),
    );
  }

  @override
  Future<AuthResponse> signIn(String email, String password) async {
    return _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  Future<void> resendEmail(String email) async {
    await _supabaseClient.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: Constants.getRedirectUrl(),
    );
  }

  @override
  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  @override
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(
      email,
      redirectTo: Constants.getRedirectUrl(),
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(email: newEmail),
      emailRedirectTo: Constants.getRedirectUrl(),
    );
  }

  @override
  Future<void> signInWithLogto() async {
    // OAuthProvider enum に custom がないため queryParams で provider を上書き
    // gotrue_client の _getUrlForProvider は urlParams.addAll(queryParams) で上書きされる
    await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.discord,
      redirectTo: Constants.getRedirectUrl(),
      queryParams: {'provider': 'custom:logto'},
    );
  }
}
