import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:favlog_app/core/router/app_router.dart';
import 'package:favlog_app/presentation/providers/theme_provider.dart';
import 'package:favlog_app/services/fcm_service.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/core/config/constants.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  String? supabaseUrl;
  String? supabaseAnonKey;

  // Attempt to get environment variables passed via --dart-define (used in CI/CD)
  const String dartDefineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const String dartDefineSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  if (dartDefineSupabaseUrl.isNotEmpty &&
      dartDefineSupabaseAnonKey.isNotEmpty) {
    supabaseUrl = dartDefineSupabaseUrl;
    supabaseAnonKey = dartDefineSupabaseAnonKey;
  } else {
    // Fallback to .env file for local development
    try {
      await dotenv.load(fileName: ".env");
      supabaseUrl = dotenv.env['SUPABASE_URL'];
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    } catch (e) {
      debugPrint('Error loading .env file: $e');
    }
  }

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Supabase URL or Anon Key is not provided. Please ensure it\'s set via --dart-define or in .env file.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Firebaseの初期化（Android/iOSのみ、Webでは実行しない）
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final AppLinks _appLinks; // 型引数を削除
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initAuthListener();
    _initFCM();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Handling deep link: $uri');

    // OAuth PKCE コールバック（code パラメータあり、type なし）は
    // supabase_flutter SDK が内部で自動処理するためスキップする。
    // アプリ側でも getSessionFromUrl を呼ぶと Authorization Code が
    // 二重使用となりエラーになり、/auth に強制リダイレクトされてしまう。
    final type = uri.queryParameters['type'];
    if (uri.queryParameters.containsKey('code') &&
        (type == null || type.isEmpty)) {
      debugPrint('OAuth PKCE callback detected - handled by Supabase SDK internally');
      return;
    }

    // マジックリンク・パスワードリセット・メールアドレス変更確認等を処理
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      debugPrint('Deep link session recovery handled');
    } catch (e) {
      debugPrint('Deep link error: $e');
      // エラーの種類に応じて適切な処理を行う
      if (e.toString().contains('otp_expired') ||
          e.toString().contains('invalid')) {
        // リンクが期限切れまたは無効の場合
        final context = ref
            .read(goRouterProvider)
            .routerDelegate
            .navigatorKey
            .currentContext;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('リンクの有効期限が切れているか、無効です。再度お試しください。'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        // 認証画面にリダイレクト
        ref.read(goRouterProvider).go('/auth');
      }
    }
  }

  void _initAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final AuthChangeEvent event = data.event;
      debugPrint('Auth State Change: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        ref.read(goRouterProvider).go('/reset-password');
      } else if (event == AuthChangeEvent.signedIn) {
        // Discord ログインの場合、ギルドメンバーシップを検証
        _verifyDiscordMembershipIfNeeded();
        // ログイン時にFCMトークンを取得・保存
        if (!kIsWeb) {
          final fcmService = ref.read(fcmServiceProvider);
          fcmService.refreshToken();
        }
      } else if (event == AuthChangeEvent.userUpdated) {
        // メールアドレス変更完了時など
        final session = data.session;
        // userUpdatedイベントが発生し、且つセッションが存在する場合は
        // メールアドレス変更が完了した可能性があるため、確認画面へ遷移
        if (session != null) {
          ref.read(goRouterProvider).go('/confirm-email-change');
        }

        // SnackBarを表示してユーザーに通知する
        final context = ref
            .read(goRouterProvider)
            .routerDelegate
            .navigatorKey
            .currentContext;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ユーザー情報が更新されました。'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  Future<void> _verifyDiscordMembershipIfNeeded() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    // providerToken が存在する場合のみ Discord OAuth セッションと判断する。
    // メール/パスワードでログインした場合は providerToken が常に null となるため、
    // Discord ギルドメンバーシップの検証をスキップする。
    final providerToken = session.providerToken;
    if (providerToken == null) return;

    final user = session.user;
    final isDiscord =
        user.appMetadata['provider'] == 'discord' ||
        (user.appMetadata['providers'] as List?)?.contains('discord') == true;
    if (!isDiscord) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final isVerified = await authRepo.verifyDiscordGuildMembership(
        providerToken,
      );
      if (!isVerified) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          final ctx = ref
              .read(goRouterProvider)
              .routerDelegate
              .navigatorKey
              .currentContext;
          if (ctx != null && ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('指定された Discord サーバーに参加していないため、ログインできません。'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          ref.read(goRouterProvider).go('/auth');
        }
      }
    } catch (e) {
      // 一時的なエラー（Discord API 障害・ネットワーク障害等）はログのみ。
      // 正規ユーザーの強制ログアウトを防ぐため、この場合はログインを許可する。
      debugPrint('Discord guild verification error: $e');
    }
  }

  /// FCMサービスの初期化
  void _initFCM() async {
    if (!kIsWeb) {
      try {
        final fcmService = ref.read(fcmServiceProvider);
        await fcmService.initialize();
      } catch (e) {
        debugPrint('FCM initialization error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      title: 'FavLog App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'KosugiMaru',
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          surface: Colors.white,
          onSurface: AppColors.textLight, // Text color
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.backgroundLight,
          foregroundColor: AppColors.textLight,
          surfaceTintColor: Colors.transparent, // Disable Material 3 tint
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
          titleLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
          titleMedium: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
          bodyMedium: TextStyle(
            fontSize: 14.0,
            height: 1.5,
            color: AppColors.textLight,
          ),
          bodySmall: TextStyle(
            fontSize: 12.0,
            height: 1.5,
            color: AppColors.subtextLight,
          ),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.subtextDark,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'KosugiMaru',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          surface: AppColors.cardDark,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.cardDark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14.0,
            height: 1.5,
            color: Colors.white,
          ),
          bodySmall: TextStyle(
            fontSize: 12.0,
            height: 1.5,
            color: AppColors.subtextDark,
          ),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.subtextDark,
        ),
      ),
      themeMode: ref.watch(themeModeProvider),
    );
  }
}
