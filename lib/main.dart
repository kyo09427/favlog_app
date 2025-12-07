import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/core/router/app_router.dart';
import 'package:favlog_app/presentation/providers/theme_provider.dart';

// Define a Riverpod provider for SupabaseClient
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  String? supabaseUrl;
  String? supabaseAnonKey;

  // Attempt to get environment variables passed via --dart-define (used in CI/CD)
  const String dartDefineSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const String dartDefineSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (dartDefineSupabaseUrl.isNotEmpty && dartDefineSupabaseAnonKey.isNotEmpty) {
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
    throw Exception('Supabase URL or Anon Key is not provided. Please ensure it\'s set via --dart-define or in .env file.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
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
    // Supabaseが発行したディープリンク（マジックリンク、パスワードリセット、メールアドレス変更確認など）は
    // URLにセッション情報を含んでいる可能性があるため、常にセッション回復を試みる。
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (e) {
      debugPrint('Deep link error: $e');
      // エラーの種類に応じて適切な処理を行う
      if (e.toString().contains('otp_expired') || e.toString().contains('invalid')) {
        // リンクが期限切れまたは無効の場合
        final context = ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;
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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        ref.read(goRouterProvider).go('/reset-password');
      } else if (event == AuthChangeEvent.userUpdated) {
        // メールアドレス変更完了時など
        // SnackBarを表示してユーザーに通知する
        final context = ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;
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
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          bodyMedium: TextStyle(fontSize: 14.0, height: 1.5, color: Color(0xFF1F2937)),
          bodySmall: TextStyle(fontSize: 12.0, height: 1.5, color: Color(0xFF6B7280)),
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
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14.0, height: 1.5, color: Colors.white),
          bodySmall: TextStyle(fontSize: 12.0, height: 1.5, color: Color(0xFF9CA3AF)),
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