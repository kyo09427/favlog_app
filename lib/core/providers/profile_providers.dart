import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_profile_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../main.dart'; // Import the main.dart to use supabaseProvider

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(supabaseProvider));
});