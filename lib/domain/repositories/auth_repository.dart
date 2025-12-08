import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<AuthResponse> signUp(String email, String password, {Map<String, dynamic>? data});
  Future<AuthResponse> signIn(String email, String password);
  Future<void> resendEmail(String email); // Add this method
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
  User? getCurrentUser();
  
  // 新規追加: パスワード変更関連
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);
  
  // 新規追加: メールアドレス変更関連
  Future<void> updateEmail(String newEmail);
}