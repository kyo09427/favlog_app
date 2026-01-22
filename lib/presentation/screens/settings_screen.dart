// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../../core/providers/notification_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../providers/update_provider.dart';
import '../../utils/update_ui_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF102216)
        : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final borderColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);
    const primaryColor = Color(0xFF13EC5B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          '設定',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            context,
            title: 'アプリ設定',
            children: [
              _buildSettingsItem(
                context,
                title: 'テーマ設定',
                icon: Icons.brightness_6_outlined,
                onTap: () => _showThemeSelectionDialog(context, ref),
                primaryColor: primaryColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
                trailing: Text(
                  _getThemeModeLabel(ref.watch(themeModeProvider)),
                  style: TextStyle(color: mutedTextColor, fontSize: 14),
                ),
              ),
              _buildSettingsItem(
                context,
                title: 'アップデートを確認',
                icon: Icons.system_update,
                onTap: () => _checkForUpdatesManually(context, ref),
                primaryColor: primaryColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
                trailing: ref
                    .watch(currentVersionProvider)
                    .when(
                      data: (version) => Text(
                        'v$version',
                        style: TextStyle(color: mutedTextColor, fontSize: 14),
                      ),
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
              ),
            ],
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
          ),
          const SizedBox(height: 24),
          _buildNotificationSettingsSection(
            context,
            ref,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            title: 'アカウント',
            children: [
              _buildSettingsItem(
                context,
                title: 'パスワードを変更',
                icon: Icons.lock_outline,
                onTap: () {
                  context.push('/password-reset-request');
                },
                primaryColor: primaryColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
              ),
              _buildSettingsItem(
                context,
                title: 'メールアドレスを変更',
                icon: Icons.email_outlined,
                onTap: () {
                  context.push('/update-email-request');
                },
                primaryColor: primaryColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
              ),
            ],
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            title: 'サポート',
            children: [
              _buildSettingsItem(
                context,
                title: 'お問い合わせフォーム',
                icon: Icons.contact_support_outlined,
                onTap: () async {
                  final url = Uri.parse('https://forms.gle/5ZfCAKHD8hZLRT647');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('お問い合わせフォームを開けませんでした'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                primaryColor: primaryColor,
                textColor: textColor,
                mutedTextColor: mutedTextColor,
              ),
            ],
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsSection(
    BuildContext context,
    WidgetRef ref, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedTextColor,
    required Color primaryColor,
  }) {
    final authRepository = ref.watch(authRepositoryProvider);
    final currentUser = authRepository.getCurrentUser();

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) => _buildSettingsSection(
        context,
        title: '通知設定',
        children: [
          _buildNotificationToggle(
            context: context,
            ref: ref,
            title: '新しいレビューの通知',
            description: '新しいレビューが投稿されたときに通知を受け取る',
            value: settings.enableNewReviewNotifications,
            onChanged: (value) async {
              final updateSettings = ref.read(updateUserSettingsProvider);
              await updateSettings(
                settings.copyWith(enableNewReviewNotifications: value),
              );
            },
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            primaryColor: primaryColor,
          ),
          _buildNotificationToggle(
            context: context,
            ref: ref,
            title: 'いいねの通知',
            description: '自分のレビューにいいねがついたときに通知を受け取る',
            value: settings.enableLikeNotifications,
            onChanged: (value) async {
              final updateSettings = ref.read(updateUserSettingsProvider);
              await updateSettings(
                settings.copyWith(enableLikeNotifications: value),
              );
            },
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            primaryColor: primaryColor,
          ),
          _buildNotificationToggle(
            context: context,
            ref: ref,
            title: 'コメントの通知',
            description: '自分のレビューにコメントがついたときに通知を受け取る',
            value: settings.enableCommentNotifications,
            onChanged: (value) async {
              final updateSettings = ref.read(updateUserSettingsProvider);
              await updateSettings(
                settings.copyWith(enableCommentNotifications: value),
              );
            },
            textColor: textColor,
            mutedTextColor: mutedTextColor,
            primaryColor: primaryColor,
          ),
        ],
        cardColor: cardColor,
        borderColor: borderColor,
        textColor: textColor,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildNotificationToggle({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String description,
    required bool value,
    required Future<void> Function(bool) onChanged,
    required Color textColor,
    required Color mutedTextColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: mutedTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) async {
              await onChanged(newValue);
            },
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: children
                .map(
                  (item) => Column(
                    children: [
                      item,
                      if (item != children.last)
                        Divider(
                          color: borderColor,
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color textColor,
    required Color mutedTextColor,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            Icon(Icons.arrow_forward_ios, color: mutedTextColor, size: 18),
          ],
        ),
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('ライトモード'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  context.pop();
                }
              },
            ),

            RadioListTile<ThemeMode>(
              title: const Text('ダークモード'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  context.pop();
                }
              },
            ),

            RadioListTile<ThemeMode>(
              title: const Text('システムのテーマに合わせる'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  context.pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
      case ThemeMode.system:
        return '自動(システム設定)';
    }
  }

  /// 手動でアップデートをチェック
  Future<void> _checkForUpdatesManually(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updateService = ref.read(updateServiceProvider);

      // 更新が利用可能かチェック
      final isAvailable = await updateService.isUpdateAvailable();

      // ローディングダイアログを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!isAvailable) {
        // 最新版の場合
        if (context.mounted) {
          final currentVersion = await updateService.getCurrentVersion();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('最新版です (v$currentVersion)'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // 最新バージョン情報を取得
      final latestVersion = await updateService.fetchLatestVersion();
      if (latestVersion == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('バージョン情報の取得に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 強制更新が必要かチェック
      final isForceUpdate = await updateService.isForceUpdateRequired();

      // ダイアログを表示
      if (context.mounted) {
        UpdateUiHelper.showUpdateDialog(
          context: context,
          ref: ref,
          versionInfo: latestVersion,
          isForceUpdate: isForceUpdate,
        );
      }
    } catch (e) {
      // エラーが発生した場合
      if (context.mounted) {
        Navigator.of(context).pop(); // ローディングダイアログを閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
