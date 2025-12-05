import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // GoRouterの拡張メソッドのために追加
import '../../data/repositories/supabase_auth_repository.dart';
import '../../presentation/widgets/error_dialog.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final response = await authRepository.signUp(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('登録が完了しました。メールを確認してください。'),
            ),
          );
        } else {
          await ErrorDialog.show(
            context,
            '登録に失敗しました: ${response.user.toString()}',
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        await ErrorDialog.show(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          '予期せぬエラーが発生しました: $error',
        );
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
      final authRepository = ref.read(authRepositoryProvider);
      final response = await authRepository.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ログインしました。'),
            ),
          );
          // TODO: 認証後の画面（ホームなど）に遷移する処理をここに追加
        } else {
          await ErrorDialog.show(
            context,
            'ログインに失敗しました: ${response.user.toString()}',
          );
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        await ErrorDialog.show(context, error.message);
      }
    } catch (error) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          '予期せぬエラーが発生しました: $error',
        );
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
    // HTML の色設定を Dart に移植
    const backgroundDark = Color(0xFF102216);
    const inputBackground = Color(0xFF1C271F);
    const borderColor = Color(0xFF3B5443);
    const primaryColor = Color(0xFF13EC5B);
    const mutedTextColor = Color(0xFF9DB9A6);
    const secondaryButtonColor = Color(0xFF28392E);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'FavLog',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // メールアドレス
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
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  // パスワード
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'パスワード',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'パスワードを入力',
                              hintStyle: TextStyle(
                                color: mutedTextColor,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: inputBackground,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: borderColor,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: inputBackground,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: const Icon(
                            Icons.visibility,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    // ログインボタン
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: backgroundDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.24,
                          ),
                        ),
                        child: const Text('ログイン'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 新規登録ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: _signUp,
                        style: TextButton.styleFrom(
                          backgroundColor: secondaryButtonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.24,
                          ),
                        ),
                        child: const Text('新規登録'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // パスワードをお忘れですか？
                    TextButton(
                      onPressed: () {
                        context.push('/password-reset-request');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.center,
                      ),
                      child: const Text(
                        'パスワードをお忘れですか？',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
