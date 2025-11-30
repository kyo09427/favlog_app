import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/models/profile.dart'; // Added missing import

import '../providers/profile_screen_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ここでコントローラーから初期データを読み込む
    // _usernameController.textは、ProfileScreenが最初にビルドされるときに設定される
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileScreenControllerProvider);
    final profileController = ref.read(profileScreenControllerProvider.notifier);
    final theme = Theme.of(context);

    // プロフィールデータがロードされたらTextFieldに反映
    ref.listen<AsyncValue<Profile?>>(profileScreenControllerProvider, (previous, next) {
      if (next.hasValue && next.value != null && next.value!.username != _usernameController.text) {
        _usernameController.text = next.value!.username;
      }
      if (next.hasError && previous?.hasError == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: profileState.when(
        data: (profile) {
          // 初回ロード時にプロフィールがない場合、初期プロフィールを作成
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (profile == null && !profileState.isLoading) {
              profileController.createInitialProfile();
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => profileController.pickAndUploadAvatar(),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profile?.avatarUrl != null
                            ? CachedNetworkImageProvider(profile!.avatarUrl!)
                            : null,
                        child: profile?.avatarUrl == null
                            ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          radius: 20,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'ユーザー名',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  onChanged: (value) {
                    // リアルタイム更新はしないが、変更を検知
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: profileState.isLoading
                        ? null
                        : () {
                            profileController.updateUsername(_usernameController.text);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: profileState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('プロフィールを保存', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 60, backgroundColor: Colors.white),
                const SizedBox(height: 24),
                Container(width: 200, height: 48, color: Colors.white),
                const SizedBox(height: 32),
                Container(width: 250, height: 50, color: Colors.white),
              ],
            ),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'プロフィールの読み込みに失敗しました。',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(profileScreenControllerProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}