import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _obscurePassword = true;
  bool _isSignUp = false; // ログインと新規登録を切り替えるフラグ

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      await ErrorDialog.show(context, 'メールアドレスとパスワードを入力してください');
      return;
    }

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
              backgroundColor: Color(0xFF13ec5b),
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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      await ErrorDialog.show(context, 'メールアドレスとパスワードを入力してください');
      return;
    }

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
              backgroundColor: Color(0xFF13ec5b),
            ),
          );
          // GoRouterが自動的にホーム画面にリダイレクトします
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
    const primaryColor = Color(0xFF13ec5b);
    const backgroundColor = Color(0xFFF6F8F6);
    const textColor = Color(0xFF1F2937);
    const borderColor = Color(0xFFD1D5DB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448), // max-w-md
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(top: 48, bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          'FavLog',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // アプリアイコン
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/icon/icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // メールアドレス
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'メールアドレス',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'メールアドレスを入力',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // パスワード
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'パスワード',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'パスワードを入力',
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryColor, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF9CA3AF),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ログイン/新規登録ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_isSignUp) {
                                _signUp();
                              } else {
                                _signIn();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: textColor,
                        disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F2937)),
                              ),
                            )
                          : Text(
                              _isSignUp ? '新規登録' : 'ログイン',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.24,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // アカウント切り替え
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      children: [
                        TextSpan(
                          text: _isSignUp
                              ? 'アカウントをお持ちですか？ '
                              : 'アカウントをお持ちでないですか？ ',
                        ),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                              });
                            },
                            child: const Text(
                              'こちら',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // パスワードをお忘れですか？
                  GestureDetector(
                    onTap: () {
                      context.push('/password-reset-request');
                    },
                    child: const Text(
                      'パスワードをお忘れですか？',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),

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
