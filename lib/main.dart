import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:favlog_app/screens/auth_screen.dart';
import 'package:favlog_app/screens/home_screen.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qdnyhvveunwufkpxwcjn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkbnlodnZldW53dWZrcHh3Y2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMzg3NzQsImV4cCI6MjA3OTcxNDc3NH0.tauMuFY5AB-q2qdocXvseNd8onu3e_-UZn43yT8Os9Y',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FavLog App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final session = snapshot.data?.session;
          if (session == null) {
            return const AuthScreen();
          } else {
            return const HomeScreen();
          }
        },
      ),
    );
  }
}
