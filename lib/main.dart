import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:favlog_app/presentation/screens/auth_screen.dart'; // Updated path
import 'package:favlog_app/presentation/screens/home_screen.dart'; // Updated path
import 'package:favlog_app/presentation/screens/email_verification_screen.dart'; // Add this import
import 'package:favlog_app/core/providers/auth_providers.dart'; // Import authStateChangesProvider

// Define a Riverpod provider for SupabaseClient
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load .env file

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // Use environment variable
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Use environment variable
  );
  // Wrap the entire application with ProviderScope
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget { // Change StatelessWidget to ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef ref
    final authState = ref.watch(authStateChangesProvider); // Use authStateChangesProvider
    return MaterialApp(
      title: 'FavLog App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (authState) {
          final session = authState.session;
          if (session == null) {
            return const AuthScreen();
          } else {
            // セッションがあるがメールが未確認の場合、EmailVerificationScreenへ
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
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
