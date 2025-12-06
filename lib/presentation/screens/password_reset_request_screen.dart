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
      appBar: AppBar(
        backgroundColor: backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
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
