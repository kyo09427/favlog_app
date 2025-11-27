import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<AuthResponse> signUp(String email, String password);
  Future<AuthResponse> signIn(String email, String password);
  Future<void> resendEmail(String email); // Add this method
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
  User? getCurrentUser();
}