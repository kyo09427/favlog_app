import '../models/profile.dart';

abstract class ProfileRepository {
  Future<Profile?> fetchProfile(String userId);
  Future<void> updateProfile(Profile profile);
  // Optional: Add a stream for real-time profile updates if needed
  // Stream<Profile?> watchProfile(String userId);
}