import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpdateEmailSentScreen extends StatelessWidget {
  const UpdateEmailSentScreen({super.key});

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
                    '確認メールを送信しました',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '新しいメールアドレスへ確認用のリンクをお送りしました。\nメールボックスをご確認ください。',
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
                      onPressed: () => context.go('/auth'), // ログイン後の画面に戻る、またはログイン画面へ
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
