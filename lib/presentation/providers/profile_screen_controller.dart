
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:favlog_app/core/providers/profile_providers.dart';
import 'package:favlog_app/data/repositories/supabase_auth_repository.dart';
import 'package:favlog_app/main.dart';
import 'package:favlog_app/core/providers/common_providers.dart';
import 'package:favlog_app/core/services/image_compressor.dart';

class ProfileScreenController extends StateNotifier<AsyncValue<Profile?>> {
  final ProfileRepository _profileRepository;
  final SupabaseClient _supabaseClient;
  final AuthRepository _authRepository;
  final Ref _ref;
  final ImagePicker _imagePicker;
  final ImageCompressor _imageCompressor;
  bool _isDisposed = false;
  bool _isInitializing = false;

  ProfileScreenController(
    this._profileRepository,
    this._supabaseClient,
    this._authRepository,
    this._ref,
    this._imagePicker,
    this._imageCompressor,
  ) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_isDisposed) return;
    
    state = const AsyncValue.loading();
    try {
      final currentUser = _authRepository.getCurrentUser();
      if (currentUser == null) {
        if (!_isDisposed) {
          state = AsyncValue.error('ユーザーがログインしていません', StackTrace.current);
        }
        return;
      }
      
      final profile = await _profileRepository.fetchProfile(currentUser.id);
      
      if (_isDisposed) return;
      
      // プロフィールが存在しない場合は自動作成
      if (profile == null && !_isInitializing) {
        _isInitializing = true;
        await _createInitialProfile(currentUser);
        _isInitializing = false;
      } else {
        state = AsyncValue.data(profile);
      }
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> _createInitialProfile(User user) async {
    if (_isDisposed) return;
    
    try {
      final newProfile = Profile(
        id: user.id,
        username: user.email?.split('@').first ?? 'User',
        avatarUrl: null,
      );
      
      await _profileRepository.updateProfile(newProfile);
      
      if (!_isDisposed) {
        state = AsyncValue.data(newProfile);
      }
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error('初期プロフィールの作成に失敗しました: $e', st);
      }
    }
  }

  Future<void> updateUsername(String newUsername) async {
    if (_isDisposed) return;
    
    final currentProfile = state.value;
    if (currentProfile == null) {
      state = AsyncValue.error('プロフィールが見つかりません', StackTrace.current);
      return;
    }
    
    if (newUsername.trim().isEmpty) {
      state = AsyncValue.error('ユーザー名を入力してください', StackTrace.current);
      return;
    }
    
    state = const AsyncValue.loading();
    try {
      final updatedProfile = currentProfile.copyWith(username: newUsername.trim());
      await _profileRepository.updateProfile(updatedProfile);
      
      if (!_isDisposed) {
        state = AsyncValue.data(updatedProfile);
      }
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error('プロフィールの更新に失敗しました: $e', st);
      }
    }
  }

  Future<void> pickAndUploadAvatar() async {
    if (_isDisposed) return;
    
    final currentUser = _authRepository.getCurrentUser();
    if (currentUser == null) {
      state = AsyncValue.error('ユーザーがログインしていません', StackTrace.current);
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return; // ユーザーがキャンセル

      if (_isDisposed) return;

      state = const AsyncValue.loading();

      final imageBytes = await image.readAsBytes();
      // 画像を圧縮
      final compressedBytes = await _imageCompressor.compressImage(
        imageBytes,
        maxWidth: 512,
        maxHeight: 512,
        quality: 80,
      );

      final fileName = '${const Uuid().v4()}.jpg';
      final path = '${currentUser.id}/$fileName';

      // 古いアバターのクリーンアップ（オプション）
      final currentProfile = state.value;
      if (currentProfile?.avatarUrl != null) {
        try {
          final oldPath = currentProfile!.avatarUrl!.split('/avatars/').last;
          await _supabaseClient.storage.from('avatars').remove([oldPath]);
        } catch (e) {
          // 古い画像の削除失敗は無視
        }
      }

      // 新しい画像をアップロード (uploadBinaryを使用)
      await _supabaseClient.storage.from('avatars').uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(
                cacheControl: '3600', upsert: true, contentType: 'image/webp'),
          );

      final publicUrl = _supabaseClient.storage.from('avatars').getPublicUrl(path);

      Profile updatedProfile;
      if (currentProfile != null) {
        updatedProfile = currentProfile.copyWith(avatarUrl: publicUrl);
      } else {
        updatedProfile = Profile(
          id: currentUser.id,
          username: currentUser.email?.split('@').first ?? 'User',
          avatarUrl: publicUrl,
        );
      }

      await _profileRepository.updateProfile(updatedProfile);

      if (!_isDisposed) {
        state = AsyncValue.data(updatedProfile);
      }
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error('アバターのアップロードに失敗しました: $e', st);
      }
    }
  }

  Future<void> refresh() async {
    await _loadProfile();
  }
}

final profileScreenControllerProvider =
    StateNotifierProvider<ProfileScreenController, AsyncValue<Profile?>>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  final supabaseClient = ref.watch(supabaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  final imagePicker = ref.watch(imagePickerProvider);
  final imageCompressor = ref.watch(imageCompressorProvider);
  return ProfileScreenController(
    profileRepository,
    supabaseClient,
    authRepository,
    ref,
    imagePicker,
    imageCompressor,
  );
});
