import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_auth_repository.dart';

class UpdateEmailState {
  final String newEmail;
  final bool isLoading;
  final String? error;
  final bool isEmailSent; // メールアドレス変更確認メールが送信されたかどうか

  UpdateEmailState({
    this.newEmail = '',
    this.isLoading = false,
    this.error,
    this.isEmailSent = false,
  });

  UpdateEmailState copyWith({
    String? newEmail,
    bool? isLoading,
    String? error,
    bool? isEmailSent,
  }) {
    return UpdateEmailState(
      newEmail: newEmail ?? this.newEmail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isEmailSent: isEmailSent ?? this.isEmailSent,
    );
  }
}

final updateEmailControllerProvider =
    StateNotifierProvider<UpdateEmailController, UpdateEmailState>((ref) {
  return UpdateEmailController(ref);
});

class UpdateEmailController extends StateNotifier<UpdateEmailState> {
  final Ref _ref;

  UpdateEmailController(this._ref) : super(UpdateEmailState());

  void updateNewEmail(String email) {
    state = state.copyWith(newEmail: email);
  }

  Future<void> sendEmailUpdate() async {
    if (state.newEmail.trim().isEmpty) {
      state = state.copyWith(error: '新しいメールアドレスを入力してください');
      return;
    }
    if (!state.newEmail.contains('@')) {
      state = state.copyWith(error: '有効なメールアドレスを入力してください');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authRepository = _ref.read(authRepositoryProvider);
      // SupabaseのupdateUserメソッドは、redirectToを指定しない場合、
      // 現在のセッション内でメールアドレスが変更され、確認メールが送信されます。
      // 確認メールのリンクをクリックすると、メールアドレスの変更が確定します。
      await authRepository.updateEmail(state.newEmail.trim());

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
