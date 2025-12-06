import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/update_email_controller.dart';

class UpdateEmailRequestScreen extends ConsumerStatefulWidget {
  const UpdateEmailRequestScreen({super.key});

  @override
  ConsumerState<UpdateEmailRequestScreen> createState() =>
      _UpdateEmailRequestScreenState();
}

class _UpdateEmailRequestScreenState
    extends ConsumerState<UpdateEmailRequestScreen> {
  final _newEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateEmailState = ref.watch(updateEmailControllerProvider);
    final updateEmailController =
        ref.read(updateEmailControllerProvider.notifier);

    // メール送信完了時の画面遷移
    ref.listen<UpdateEmailState>(
      updateEmailControllerProvider,
      (previous, next) {
        if (next.isEmailSent && !previous!.isEmailSent) {
          context.push('/update-email-sent');
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
        title: const Text(
          'メールアドレス変更',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundDark,
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
                      Icons.email_outlined,
                      size: 64,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'メールアドレスの変更',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '新しいメールアドレスを入力してください.\n確認用のメールをお送りします。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 新しいメールアドレス入力
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '新しいメールアドレス',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '新しいメールアドレスを入力',
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
                      onChanged: updateEmailController.updateNewEmail,
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
                    if (updateEmailState.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        updateEmailState.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // 変更リクエスト送信ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: updateEmailState.isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  updateEmailController.sendEmailUpdate();
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
                        child: updateEmailState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: backgroundDark,
                                ),
                              )
                            : const Text('変更リクエストを送信'),
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
