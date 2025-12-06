import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfirmEmailChangeScreen extends StatelessWidget {
  const ConfirmEmailChangeScreen({super.key});

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
                    Icons.check_circle_outline,
                    size: 80,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'メールアドレス変更完了',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'メールアドレスの変更が完了しました.\n引き続きサービスをご利用いただけます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedTextColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/auth'), // ログイン画面へ戻る
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
