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
import 'package:favlog_app/providers/update_provider.dart';
import 'package:favlog_app/models/version_info.dart';
import 'package:favlog_app/utils/update_ui_helper.dart';
import 'package:favlog_app/services/fcm_service.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';

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
    // アプリ起動後にバージョンチェックを実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    // getInitialAppLink().then((uri) {
    //   if (uri != null) {
    //     _handleDeepLink(uri);
    //   }
    // });
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Handling deep link: $uri');
    // Supabaseが発行したディープリンク（マジックリンク、パスワードリセット、メールアドレス変更確認など）は
    // URLにセッション情報を含んでいる可能性があるため、常にセッション回復を試みる。
    try {
      final res = await Supabase.instance.client.auth.getSessionFromUrl(uri);
      debugPrint('Deep link session recovery success: ${res.session != null}');
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

  /// アプリ起動時のバージョンチェック
  Future<void> _checkForUpdates() async {
    try {
      final updateService = ref.read(updateServiceProvider);

      // 最終チェックから24時間以上経過している場合のみチェック
      final shouldCheck = await updateService.shouldCheckForUpdate();
      if (!shouldCheck) {
        return;
      }

      // 更新が利用可能かチェック
      final isAvailable = await updateService.isUpdateAvailable();
      if (!isAvailable) {
        // 最終チェック日時を更新
        await updateService.updateLastCheckTime();
        return;
      }

      // 最新バージョン情報を取得
      final latestVersion = await updateService.fetchLatestVersion();
      if (latestVersion == null) {
        return;
      }

      // 強制更新が必要かチェック
      final isForceUpdate = await updateService.isForceUpdateRequired();

      // 最終チェック日時を更新
      await updateService.updateLastCheckTime();

      // ダイアログを表示
      if (mounted) {
        _showUpdateDialog(latestVersion, isForceUpdate);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  /// アップデートダイアログを表示
  void _showUpdateDialog(VersionInfo versionInfo, bool isForceUpdate) {
    if (!mounted) return;
    UpdateUiHelper.showUpdateDialog(
      context: context,
      ref: ref,
      versionInfo: versionInfo,
      isForceUpdate: isForceUpdate,
    );
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
          seedColor: const Color(0xFF13EC5B),
          brightness: Brightness.light,
          primary: const Color(0xFF13EC5B),
          surface: Colors.white,
          onSurface: const Color(0xFF1F2937), // Text color
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFF6F8F6),
          foregroundColor: Color(0xFF1F2937),
          surfaceTintColor: Colors.transparent, // Disable Material 3 tint
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          titleLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          titleMedium: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          bodyMedium: TextStyle(
            fontSize: 14.0,
            height: 1.5,
            color: Color(0xFF1F2937),
          ),
          bodySmall: TextStyle(
            fontSize: 12.0,
            height: 1.5,
            color: Color(0xFF6B7280),
          ),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF13EC5B),
          unselectedItemColor: Color(0xFF9CA3AF),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'KosugiMaru',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF13EC5B),
          brightness: Brightness.dark,
          primary: const Color(0xFF13EC5B),
          surface: const Color(0xFF1C1C1E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF102216),
        cardColor: const Color(0xFF1C1C1E),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF102216),
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
            color: Color(0xFF9CA3AF),
          ),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C1E),
          selectedItemColor: Color(0xFF13EC5B),
          unselectedItemColor: Color(0xFF9CA3AF),
        ),
      ),
      themeMode: ref.watch(themeModeProvider),
    );
  }
}
