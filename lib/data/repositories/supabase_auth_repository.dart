import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      emailRedirectTo: Constants.siteUrl,
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
      emailRedirectTo: Constants.siteUrl,
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
      redirectTo: Constants.siteUrl,
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
      emailRedirectTo: Constants.siteUrl,
    );
  }

  @override
  Future<void> signInWithDiscord() async {
    await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.discord,
      redirectTo: kIsWeb ? null : Constants.customScheme,
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
    if (response.status == 200) {
      final data = jsonDecode(response.data as String);
      return data['verified'] == true;
    }
    return false;
  }
}
