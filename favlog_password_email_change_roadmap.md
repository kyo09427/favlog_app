# FavLog パスワード・メールアドレス変更機能 実装ロードマップ

## 📋 概要

本ドキュメントは、FavLogアプリケーションに以下の機能を追加するための詳細な実装計画です：

1. **パスワード変更機能**
2. **メールアドレス変更機能**

---

## 🎯 実装方針

### Supabase Authの活用

Supabase Authには以下の組み込み機能があります：

- **パスワードリセット**: `resetPasswordForEmail()` でリセットメール送信
- **パスワード更新**: `updateUser()` で新しいパスワードを設定
- **メールアドレス変更**: `updateUser()` で新しいメールアドレスを設定（確認メール送信）

これらのAPIを活用し、セキュアで標準的な実装を行います。

---

## 🗺️ フェーズ1: バックエンド設定（Supabase）

### 1.1 Supabaseダッシュボード設定

#### パスワードリセットURL設定
```
1. Supabaseダッシュボード → Authentication → URL Configuration
2. "Site URL" を確認: https://your-app-domain.com
3. "Redirect URLs" に以下を追加:
   - https://your-app-domain.com/reset-password
   - io.supabase.flutterquickstart://reset-password (モバイル用)
```

#### メールテンプレートのカスタマイズ
```
1. Authentication → Email Templates
2. 以下のテンプレートを日本語化・カスタマイズ:
   - "Reset Password" (パスワードリセット)
   - "Change Email Address" (メールアドレス変更確認)
```

**パスワードリセットメールの例:**
```html
<h2>パスワードの再設定</h2>
<p>パスワードリセットのリクエストを受け付けました。</p>
<p>以下のリンクをクリックして、新しいパスワードを設定してください：</p>
<p><a href="{{ .ConfirmationURL }}">パスワードを再設定する</a></p>
<p>このリンクは24時間有効です。</p>
<p>※このリクエストに心当たりがない場合は、このメールを無視してください。</p>
```

**メールアドレス変更確認メールの例:**
```html
<h2>メールアドレス変更の確認</h2>
<p>新しいメールアドレスへの変更リクエストを受け付けました。</p>
<p>以下のリンクをクリックして、メールアドレスの変更を完了してください：</p>
<p><a href="{{ .ConfirmationURL }}">メールアドレス変更を確認する</a></p>
<p>このリンクは24時間有効です。</p>
```

### 1.2 セキュリティ設定の確認

```
1. Authentication → Settings
2. 以下を確認:
   - "Enable email confirmations" = ON
   - "Secure password change" = ON (パスワード変更時に確認メール)
```

---

## 🗺️ フェーズ2: データモデル・リポジトリ拡張

### 2.1 AuthRepositoryインターフェース拡張

**ファイル:** `lib/domain/repositories/auth_repository.dart`

```dart
abstract class AuthRepository {
  // 既存のメソッド
  Future<AuthResponse> signUp(String email, String password);
  Future<AuthResponse> signIn(String email, String password);
  Future<void> resendEmail(String email);
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
  User? getCurrentUser();
  
  // 新規追加: パスワード変更関連
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);
  
  // 新規追加: メールアドレス変更関連
  Future<void> updateEmail(String newEmail);
}
```

### 2.2 SupabaseAuthRepository実装拡張

**ファイル:** `lib/data/repositories/supabase_auth_repository.dart`

```dart
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabaseClient;

  SupabaseAuthRepository(this._supabaseClient);

  // ... 既存のメソッド ...

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutterquickstart://reset-password',
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
    );
  }
}
```

---

## 🗺️ フェーズ3: パスワード変更機能実装

### 3.1 画面構成

```
1. パスワードリセットリクエスト画面
   - メールアドレス入力
   - リセットメール送信ボタン
   
2. メール送信完了画面
   - 確認メッセージ
   - メール受信待ち案内
   
3. 新しいパスワード設定画面
   - 新しいパスワード入力（2回）
   - パスワード強度インジケーター
   - 更新ボタン
```

### 3.2 コントローラー作成

**ファイル:** `lib/presentation/providers/password_reset_controller.dart`

```dart
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
```

**ファイル:** `lib/presentation/providers/update_password_controller.dart`

```dart
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
```

### 3.3 画面実装

#### 3.3.1 パスワードリセットリクエスト画面

**ファイル:** `lib/presentation/screens/password_reset_request_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/password_reset_controller.dart';

class PasswordResetRequestScreen extends ConsumerStatefulWidget {
  const PasswordResetRequestScreen({super.key});

  @override
  ConsumerState<PasswordResetRequestScreen> createState() =>
      _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState
    extends ConsumerState<PasswordResetRequestScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordResetState = ref.watch(passwordResetControllerProvider);
    final passwordResetController =
        ref.read(passwordResetControllerProvider.notifier);

    // メール送信完了時の画面遷移
    ref.listen<PasswordResetState>(
      passwordResetControllerProvider,
      (previous, next) {
        if (next.isEmailSent && !previous!.isEmailSent) {
          context.push('/password-reset-email-sent');
        }
      },
    );

    const backgroundDark = Color(0xFF102216);
    const inputBackground = Color(0xFF1C271F);
    const borderColor = Color(0xFF3B5443);
    const primaryColor = Color(0xFF13EC5B);
    const mutedTextColor = Color(0xFF9DB9A6);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'パスワードの再設定',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ご登録のメールアドレスを入力してください。\nパスワード再設定用のリンクをお送りします。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // メールアドレス入力
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'メールアドレス',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'メールアドレスを入力',
                        hintStyle: const TextStyle(
                          color: mutedTextColor,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: inputBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: passwordResetController.updateEmail,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'メールアドレスを入力してください';
                        }
                        if (!value.contains('@')) {
                          return '有効なメールアドレスを入力してください';
                        }
                        return null;
                      },
                    ),
                    if (passwordResetState.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        passwordResetState.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // 送信ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: passwordResetState.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  passwordResetController.sendResetEmail();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: backgroundDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: passwordResetState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: backgroundDark,
                                ),
                              )
                            : const Text('リセットメールを送信'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 戻るボタン
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'ログイン画面に戻る',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 3.3.2 メール送信完了画面

**ファイル:** `lib/presentation/screens/password_reset_email_sent_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PasswordResetEmailSentScreen extends StatelessWidget {
  const PasswordResetEmailSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundDark = Color(0xFF102216);
    const primaryColor = Color(0xFF13EC5B);
    const mutedTextColor = Color(0xFF9DB9A6);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'メールを送信しました',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'パスワード再設定用のリンクをメールでお送りしました。\nメールボックスをご確認ください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📧 メールが届かない場合',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• 迷惑メールフォルダをご確認ください\n'
                          '• メールアドレスに誤りがないかご確認ください\n'
                          '• 数分お待ちいただいてから再度お試しください',
                          style: TextStyle(
                            color: mutedTextColor,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/auth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: backgroundDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('ログイン画面に戻る'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### 3.3.3 新しいパスワード設定画面

**ファイル:** `lib/presentation/screens/update_password_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/update_password_controller.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updatePasswordState = ref.watch(updatePasswordControllerProvider);
    final updatePasswordController =
        ref.read(updatePasswordControllerProvider.notifier);

    // パスワード更新完了時の画面遷移
    ref.listen<UpdatePasswordState>(
      updatePasswordControllerProvider,
      (previous, next) {
        if (next.isPasswordUpdated && !previous!.isPasswordUpdated) {
          context.go('/auth');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('パスワードを更新しました。新しいパスワードでログインしてください。'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );

    const backgroundDark = Color(0xFF102216);
    const inputBackground = Color(0xFF1C271F);
    const borderColor = Color(0xFF3B5443);
    const primaryColor = Color(0xFF13EC5B);
    const mutedTextColor = Color(0xFF9DB9A6);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '新しいパスワードを設定',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '新しいパスワードを入力してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 新しいパスワード
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '新しいパスワード',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '8文字以上（大小英数字を含む）',
                        hintStyle: const TextStyle(
                          color: mutedTextColor,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: inputBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: mutedTextColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: updatePasswordController.updateNewPassword,
                      validator: (value) =>
                          updatePasswordController.validatePassword(value ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // パスワード確認
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'パスワード（確認）',
                        style: TextStyle(
                