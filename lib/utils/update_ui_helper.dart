import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/version_info.dart';
import '../core/providers/update_provider.dart';
import '../widgets/update_dialog.dart';
import '../widgets/download_progress_dialog.dart';
import 'package:go_router/go_router.dart';

/// アップデートUIを表示するためのユーティリティ
class UpdateUiHelper {
  /// アップデートダイアログを表示
  static void showUpdateDialog({
    required BuildContext context,
    required WidgetRef ref,
    required VersionInfo versionInfo,
    required bool isForceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (dialogContext) => UpdateDialog(
        versionInfo: versionInfo,
        isForceUpdate: isForceUpdate,
        onUpdate: () {
          Navigator.of(dialogContext).pop();
          startUpdate(
            context: context,
            ref: ref,
            downloadUrl: versionInfo.downloadUrl,
          );
        },
        onLater: isForceUpdate
            ? null
            : () {
                Navigator.of(dialogContext).pop();
              },
      ),
    );
  }

  /// アップデート（ダウンロード進捗）を開始
  static void startUpdate({
    required BuildContext context,
    required WidgetRef ref,
    required String downloadUrl,
  }) {
    final apkInstaller = ref.read(apkInstallerProvider);

    int currentProgress = 0;
    String currentStatus = 'ダウンロードを準備中...';
    String? currentError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // ストリームの監視を一元化
          // 注: 実際の実装では、これらのリスナーはダイアログが閉じられたときにキャンセルされるべきですが、
          // OTAアップデート中はダイアログが閉じられないため（エラー時を除く）、簡略化しています。
          final progressSub = apkInstaller.progressStream.listen((progress) {
            if (context.mounted) {
              setState(() {
                currentProgress = progress;
              });
            }
          });

          final statusSub = apkInstaller.statusStream.listen((status) {
            if (context.mounted) {
              setState(() {
                currentStatus = status;
              });
            }
          });

          final errorSub = apkInstaller.errorStream.listen((error) {
            if (context.mounted) {
              setState(() {
                currentError = error;
              });
            }
          });

          return DownloadProgressDialog(
            progress: currentProgress,
            status: currentStatus,
            error: currentError,
            onClose: currentError != null
                ? () {
                    progressSub.cancel();
                    statusSub.cancel();
                    errorSub.cancel();
                    Navigator.of(dialogContext).pop();

                    // 権限エラーの場合、ガイド画面への遷移を促す（オプション）
                    // ここではダイアログ内のボタンで制御するため、ここでの遷移は行わない
                  }
                : null,
            onOpenGuide:
                currentError != null && currentError!.contains('インストール権限')
                ? () {
                    progressSub.cancel();
                    statusSub.cancel();
                    errorSub.cancel();
                    Navigator.of(dialogContext).pop();
                    context.push('/settings/version/permission-guide');
                  }
                : null,
          );
        },
      ),
    );

    // ダウンロードを開始
    apkInstaller.downloadAndInstall(downloadUrl);
  }

  /// アプリ起動時の自動アップデートチェック
  ///
  /// - 24時間以内にチェック済みの場合はスキップ
  /// - 更新があればダイアログを表示
  /// - インストール権限がなければ権限ガイド画面へ誘導
  static Future<void> showAutoUpdateCheck({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final updateService = ref.read(updateServiceProvider);

    // 24時間以内にチェック済みならスキップ
    if (!await updateService.shouldCheckForUpdate()) return;
    await updateService.updateLastCheckTime();

    final isAvailable = await updateService.isUpdateAvailable();
    if (!isAvailable) return;

    final versionInfo = await updateService.fetchLatestVersion();
    if (versionInfo == null) return;

    final isForce = await updateService.isForceUpdateRequired();

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (dialogContext) => UpdateDialog(
        versionInfo: versionInfo,
        isForceUpdate: isForce,
        onUpdate: () async {
          Navigator.of(dialogContext).pop();

          // インストール権限を確認
          final status = await Permission.requestInstallPackages.status;
          if (!context.mounted) return;

          if (status.isGranted) {
            // 権限あり → ダウンロード開始
            startUpdate(
              context: context,
              ref: ref,
              downloadUrl: versionInfo.downloadUrl,
            );
          } else {
            // 権限なし → ガイド画面へ
            context.push('/settings/version/permission-guide');
          }
        },
        onLater: isForce ? null : () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}
