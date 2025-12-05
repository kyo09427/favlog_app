import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // AuthExceptionのために追加
import '../../data/repositories/supabase_auth_repository.dart'; // authRepositoryProviderのために追加

class UpdatePasswordState {
  final String newPassword;
  final String confirmPassword;
  final bool isLoading;
  final String? error;
  final bool isPasswordUpdated;

  UpdatePasswordState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.error,
    this.isPasswordUpdated = false,
  });

  UpdatePasswordState copyWith({
    String? newPassword,
    String? confirmPassword,
    bool? isLoading,
    String? error,
    bool? isPasswordUpdated,
  }) {
    return UpdatePasswordState(
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPasswordUpdated: isPasswordUpdated ?? this.isPasswordUpdated,
    );
  }
}

final updatePasswordControllerProvider =
    StateNotifierProvider<UpdatePasswordController, UpdatePasswordState>((ref) {
  return UpdatePasswordController(ref);
});

class UpdatePasswordController extends StateNotifier<UpdatePasswordState> {
  final Ref _ref;

  UpdatePasswordController(this._ref) : super(UpdatePasswordState());

  void updateNewPassword(String password) {
    state = state.copyWith(newPassword: password);
  }

  void updateConfirmPassword(String password) {
    state = state.copyWith(confirmPassword: password);
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (password.length < 8) {
      return 'パスワードは8文字以上で入力してください';
    }
    // 追加のパスワード強度チェック
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return '大文字を1文字以上含めてください';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return '小文字を1文字以上含めてください';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return '数字を1文字以上含めてください';
    }
    return null;
  }

  Future<void> updatePassword() async {
    // バリデーション
    final passwordError = validatePassword(state.newPassword);
    if (passwordError != null) {
      state = state.copyWith(error: passwordError);
      return;
    }

    if (state.newPassword != state.confirmPassword) {
      state = state.copyWith(error: 'パスワードが一致しません');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.updatePassword(state.newPassword);
      
      state = state.copyWith(
        isLoading: false,
        isPasswordUpdated: true,
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