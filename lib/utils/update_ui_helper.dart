import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/version_info.dart';
import '../core/providers/update_provider.dart';
import '../services/apk_installer.dart';
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DownloadProgressScreen(
        apkInstaller: apkInstaller,
        downloadUrl: downloadUrl,
        parentContext: context,
      ),
    );
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

    // 1回のフェッチで全ての情報を取得
    final latestVersion = await updateService.fetchLatestVersion();
    await updateService.updateLastCheckTime();

    if (latestVersion == null) return;

    final currentBuildNumber = await updateService.getCurrentBuildNumber();
    if (latestVersion.versionCode <= currentBuildNumber) return;

    final currentVersion = await updateService.getCurrentVersion();
    final isForce = latestVersion.forceUpdate ||
        updateService.compareVersions(
              currentVersion,
              latestVersion.minSupportedVersion,
            ) <
            0;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (dialogContext) => UpdateDialog(
        versionInfo: latestVersion,
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
              downloadUrl: latestVersion.downloadUrl,
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

/// ダウンロード進捗ダイアログのストリーム管理を行うStatefulWidget
///
/// StatefulBuilderではビルドのたびにリスナーが追加されてしまうため、
/// initState/disposeで正しくサブスクリプションを管理する。
class _DownloadProgressScreen extends StatefulWidget {
  final ApkInstaller apkInstaller;
  final String downloadUrl;
  final BuildContext parentContext;

  const _DownloadProgressScreen({
    required this.apkInstaller,
    required this.downloadUrl,
    required this.parentContext,
  });

  @override
  State<_DownloadProgressScreen> createState() =>
      _DownloadProgressScreenState();
}

class _DownloadProgressScreenState extends State<_DownloadProgressScreen> {
  int _progress = 0;
  String _status = 'ダウンロードを準備中...';
  String? _error;

  StreamSubscription<int>? _progressSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _progressSub = widget.apkInstaller.progressStream.listen((progress) {
      if (mounted) setState(() => _progress = progress);
    });
    _statusSub = widget.apkInstaller.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
    _errorSub = widget.apkInstaller.errorStream.listen((error) {
      if (mounted) setState(() => _error = error);
    });
    widget.apkInstaller.downloadAndInstall(widget.downloadUrl);
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _statusSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _openGuide() {
    Navigator.of(context).pop();
    widget.parentContext.push('/settings/version/permission-guide');
  }

  @override
  Widget build(BuildContext context) {
    return DownloadProgressDialog(
      progress: _progress,
      status: _status,
      error: _error,
      onClose: _error != null ? _close : null,
      onOpenGuide:
          _error != null && _error!.contains('インストール権限') ? _openGuide : null,
    );
  }
}
