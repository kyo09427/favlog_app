import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Define a Riverpod provider for SupabaseClient
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
