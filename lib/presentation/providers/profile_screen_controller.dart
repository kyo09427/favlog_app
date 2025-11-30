import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/auth_repository.dart'; // Import AuthRepository
import 'package:favlog_app/core/providers/profile_providers.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart'; // Corrected import for authRepositoryProvider
import 'package:favlog_app/main.dart'; // For supabaseProvider
import 'package:favlog_app/core/providers/common_providers.dart'; // Import common providers

class ProfileScreenController extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileRepository _profileRepository;
  final SupabaseClient _supabaseClient;
  final AuthRepository _authRepository;
  final Ref _ref;
  final ImagePicker _imagePicker; // Injected ImagePicker

  ProfileScreenController(this._profileRepository, this._supabaseClient, this._authRepository, this._ref, this._imagePicker)
      : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final currentUser = _authRepository.getCurrentUser();
      if (currentUser == null) {
        state = AsyncValue.error('User not logged in', StackTrace.current);
        return;
      }
      final profile = await _profileRepository.fetchProfile(currentUser.id);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateUsername(String newUsername) async {
    final currentProfile = state.value;
    if (currentProfile == null) {
      state = AsyncValue.error('No profile to update', StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final updatedProfile = currentProfile.copyWith(username: newUsername);
      await _profileRepository.updateProfile(updatedProfile);
      state = AsyncValue.data(updatedProfile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image == null) return; // User cancelled picking an image

    final currentUser = _authRepository.getCurrentUser();
    if (currentUser == null) {
      state = AsyncValue.error('User not logged in', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final file = File(image.path);
      final fileExtension = image.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExtension';
      final path = '${currentUser.id}/$fileName';

      // Upload image to Supabase Storage
      await _supabaseClient.storage.from('avatars').upload(path, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

      // Get the public URL
      final String publicUrl = _supabaseClient.storage.from('avatars').getPublicUrl(path);

      // Update profile with new avatar URL
      final currentProfile = state.value;
      Profile updatedProfile;
      if (currentProfile != null) {
        updatedProfile = currentProfile.copyWith(avatarUrl: publicUrl);
      } else {
        // If profile doesn't exist, create a new one
        updatedProfile = Profile(
          id: currentUser.id,
          username: currentUser.email?.split('@').first ?? 'User', // Default username
          avatarUrl: publicUrl,
        );
      }
      await _profileRepository.updateProfile(updatedProfile);
      state = AsyncValue.data(updatedProfile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Method to create an initial profile if one doesn't exist
  Future<void> createInitialProfile({String? username, String? avatarUrl}) async {
    final currentUser = _authRepository.getCurrentUser();
    if (currentUser == null) {
      state = AsyncValue.error('User not logged in', StackTrace.current);
      return;
    }

    // Check if a profile already exists
    final existingProfile = await _profileRepository.fetchProfile(currentUser.id);
    if (existingProfile != null) {
      state = AsyncValue.data(existingProfile);
      return; // Profile already exists, no need to create
    }

    state = const AsyncValue.loading();
    try {
      final newProfile = Profile(
        id: currentUser.id,
        username: username ?? currentUser.email?.split('@').first ?? 'User',
        avatarUrl: avatarUrl,
      );
      await _profileRepository.updateProfile(newProfile); // Upsert will handle insertion
      state = AsyncValue.data(newProfile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileScreenControllerProvider = StateNotifierProvider<ProfileScreenController, AsyncValue<Profile?>>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  final supabaseClient = ref.watch(supabaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final imagePicker = ref.watch(imagePickerProvider); // Watch the imagePickerProvider
  return ProfileScreenController(profileRepository, supabaseClient, authRepository, ref, imagePicker);
});
