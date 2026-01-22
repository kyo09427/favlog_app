import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/version_info.dart';
import '../providers/update_provider.dart';
import '../widgets/update_dialog.dart';
import '../widgets/download_progress_dialog.dart';

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
                  }
                : null,
          );
        },
      ),
    );

    // ダウンロードを開始
    apkInstaller.downloadAndInstall(downloadUrl);
  }
}
