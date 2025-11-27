import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_auth_repository.dart'; // authRepositoryProvider をインポート
import '../../presentation/widgets/error_dialog.dart'; // Add this import

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isLoading = false;
  // String? _message; // Remove _message

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
      // _message = null; // Remove _message
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = authRepository.getCurrentUser();

      if (user == null || user.email == null) {
        throw Exception('ユーザーのメールアドレスが見つかりません。');
      }

      await authRepository.resendEmail(user.email!);
      if (mounted) {
        await ErrorDialog.show(context, '認証メールを再送しました。メールボックスをご確認ください。', title: '成功');
      }
    } on AuthException catch (e) {
      if (mounted) {
        await ErrorDialog.show(context, 'メール再送に失敗しました: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(context, 'メール再送に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メールアドレスの確認'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'ご登録いただいたメールアドレスの確認をお願いします。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                '受信トレイに送信された認証リンクをクリックしてください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _resendEmail,
                  child: const Text('認証メールを再送する'),
                ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  // ログアウトして再度ログイン画面へ
                  ref.read(authRepositoryProvider).signOut();
                },
                child: const Text('ログアウトして別のメールアドレスで登録/ログイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}