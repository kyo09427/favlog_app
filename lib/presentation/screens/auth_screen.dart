import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import '../../data/repositories/supabase_auth_repository.dart'; // Import the new repository
import '../../presentation/widgets/error_dialog.dart'; // Add this import

class AuthScreen extends ConsumerStatefulWidget { // Change StatefulWidget to ConsumerStatefulWidget
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState(); // Change State to ConsumerState
}

class _AuthScreenState extends ConsumerState<AuthScreen> { // Change State to ConsumerState
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider); // Access the auth repository
      final response = await authRepository.signUp(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登録が完了しました。メールを確認してください。')),
          );
        } else {
          // エラーダイアログを表示
          await ErrorDialog.show(context, '登録に失敗しました: ${response.user.toString()}');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        // エラーダイアログを表示
        await ErrorDialog.show(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        // エラーダイアログを表示
        await ErrorDialog.show(context, '予期せぬエラーが発生しました: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider); // Access the auth repository
      final response = await authRepository.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログインしました。')),
          );
          // Navigate to home screen or authenticated part of the app
        } else {
          // エラーダイアログを表示
          await ErrorDialog.show(context, 'ログインに失敗しました: ${response.user.toString()}');
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        // エラーダイアログを表示
        await ErrorDialog.show(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        // エラーダイアログを表示
        await ErrorDialog.show(context, '予期せぬエラーが発生しました: $error');
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FavLog')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _signIn,
                          child: const Text('ログイン'),
                        ),
                        const SizedBox(height: 16.0),
                        TextButton(
                          onPressed: _signUp,
                          child: const Text('新規登録'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}