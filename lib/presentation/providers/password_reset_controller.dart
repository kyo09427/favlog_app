import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // AuthExceptionのために追加
import '../../data/repositories/supabase_auth_repository.dart'; // authRepositoryProviderのために追加

class PasswordResetState {
  final String email;
  final bool isLoading;
  final String? error;
  final bool isEmailSent;

  PasswordResetState({
    this.email = '',
    this.isLoading = false,
    this.error,
    this.isEmailSent = false,
  });

  PasswordResetState copyWith({
    String? email,
    bool? isLoading,
    String? error,
    bool? isEmailSent,
  }) {
    return PasswordResetState(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isEmailSent: isEmailSent ?? this.isEmailSent,
    );
  }
}

final passwordResetControllerProvider =
    StateNotifierProvider<PasswordResetController, PasswordResetState>((ref) {
  return PasswordResetController(ref);
});

class PasswordResetController extends StateNotifier<PasswordResetState> {
  final Ref _ref;

  PasswordResetController(this._ref) : super(PasswordResetState());

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  Future<void> sendResetEmail() async {
    if (state.email.trim().isEmpty) {
      state = state.copyWith(error: 'メールアドレスを入力してください');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.sendPasswordResetEmail(state.email.trim());
      
      state = state.copyWith(
        isLoading: false,
        isEmailSent: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'エラー: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '予期しないエラーが発生しました',
      );
    }
  }
}
