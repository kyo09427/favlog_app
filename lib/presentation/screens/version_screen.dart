import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/update_provider.dart';
import '../../utils/update_ui_helper.dart';

class VersionScreen extends ConsumerWidget {
  const VersionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF102216)
        : const Color(0xFFF6F8F6);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111813);
    final mutedTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF61896F);
    const primaryColor = Color(0xFF13EC5B);

    final currentVersionAsync = ref.watch(currentVersionProvider);
    final isUpdateAvailableAsync = ref.watch(isUpdateAvailableProvider);
    final latestVersionAsync = ref.watch(latestVersionProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'バージョン確認',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // アプリロゴ
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF13EC5B), Color(0xFF0DBD48)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.asset(
                              'assets/icon/icon.png',
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.auto_stories,
                                  color: Colors.white,
                                  size: 48,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // アプリ名
                    Text(
                      'Favlog',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 現在のバージョン
                    currentVersionAsync.when(
                      data: (version) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '現在のバージョン',
                            style: TextStyle(
                              color: mutedTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'v$version',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : mutedTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 48),
                    // アップデート情報カード
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: isUpdateAvailableAsync.when(
                        data: (isAvailable) {
                          if (!isAvailable) {
                            return _buildNoUpdateCard(
                              isDark,
                              cardColor,
                              textColor,
                              mutedTextColor,
                            );
                          }
                          return latestVersionAsync.when(
                            data: (info) {
                              if (info == null) return const SizedBox.shrink();
                              return _buildUpdateAvailableCard(
                                info,
                                isDark,
                                cardColor,
                                textColor,
                                mutedTextColor,
                                primaryColor,
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('エラーが発生しました: $err'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // アップデートボタン（利用可能な場合のみ）
            isUpdateAvailableAsync.maybeWhen(
              data: (isAvailable) {
                if (!isAvailable) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                  child: latestVersionAsync.maybeWhen(
                    data: (info) {
                      if (info == null) return const SizedBox.shrink();
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            UpdateUiHelper.startUpdate(
                              context: context,
                              ref: ref,
                              downloadUrl: info.downloadUrl,
                            );
                          },
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: const Color(0xFF111813),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ).copyWith(
                                overlayColor: WidgetStateProperty.all(
                                  Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                          child: const Text(
                            '今すぐアップデートする',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateAvailableCard(
    dynamic info,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111813).withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: primaryColor.withValues(alpha: isDark ? 0.05 : 0.1),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_alt,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'UPDATE AVAILABLE',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  '新しいバージョンが利用可能です',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'バージョン v${info.version}',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '最新の機能追加とパフォーマンスの改善が含まれています。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedTextColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoUpdateCard(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111813).withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: const Color(0xFF13EC5B),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'お使いのアプリは最新です',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '現在、利用可能なアップデートはありません。',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
