import 'dart:convert';
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
  Future<void> signInWithDiscord() async {
    await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.discord,
      redirectTo: Constants.getRedirectUrl(),
      scopes: 'identify email guilds',
    );
  }

  @override
  String? getProviderToken() {
    return _supabaseClient.auth.currentSession?.providerToken;
  }

  @override
  Future<bool> verifyDiscordGuildMembership(String providerToken) async {
    final response = await _supabaseClient.functions.invoke(
      'verify-discord-guild',
      body: {'provider_token': providerToken},
    );

    // response.data は String / Map / null の可能性があるため安全に変換
    final Map<String, dynamic> data;
    if (response.data is String) {
      data = jsonDecode(response.data as String) as Map<String, dynamic>;
    } else if (response.data is Map) {
      data = Map<String, dynamic>.from(response.data as Map);
    } else {
      data = {};
    }

    // 200: 検証成功
    if (response.status == 200) {
      return data['verified'] == true;
    }

    // 403: ギルド未参加（正常な検証結果）
    if (response.status == 403) {
      return false;
    }

    // それ以外 (Discord API障害・内部エラー等) は例外をスロー。
    // 呼び出し側のキャッチブロックで一時エラーとして扱い、強制ログアウトしない。
    throw Exception(
      'Guild verification failed with status ${response.status}: '
      '${data['error'] ?? 'Unknown error'}',
    );
  }
}
