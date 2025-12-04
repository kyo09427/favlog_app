import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:favlog_app/presentation/screens/auth_screen.dart';
import 'package:favlog_app/presentation/screens/home_screen.dart';
import 'package:favlog_app/presentation/screens/email_verification_screen.dart';
import 'package:favlog_app/presentation/screens/search_screen.dart';
import 'package:favlog_app/presentation/screens/profile_screen.dart';
import 'package:favlog_app/core/providers/auth_providers.dart';

// Define a Riverpod provider for SupabaseClient
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Future<void> main() async {
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    
    return MaterialApp(
      title: 'FavLog App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'KosugiMaru',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold), // 投稿タイトル
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),    // ユーザー名など
          titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14.0, height: 1.5),                    // コメント文
          bodySmall: TextStyle(fontSize: 12.0, height: 1.5),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),     // UI文字（ボタンなど）
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'KosugiMaru',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold), // 投稿タイトル
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),    // ユーザー名など
          titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14.0, height: 1.5),                    // コメント文
          bodySmall: TextStyle(fontSize: 12.0, height: 1.5),
          labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),     // UI文字（ボタンなど）
        ),
      ),
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (authState) {
          final session = authState.session;
          if (session == null) {
            return const AuthScreen();
          } else {
            if (session.user?.emailConfirmedAt == null) {
              return const EmailVerificationScreen();
            }
            return const HomeScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('エラー: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // アプリを再起動
                    runApp(const ProviderScope(child: MyApp()));
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/search': (context) => const SearchScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/auth': (context) => const AuthScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      },
    );
  }
}