import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_service.dart';
import '../services/apk_installer.dart';
import '../models/version_info.dart';

/// UpdateServiceのプロバイダー
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

/// ApkInstallerのプロバイダー
final apkInstallerProvider = Provider<ApkInstaller>((ref) {
  final installer = ApkInstaller();
  ref.onDispose(() => installer.dispose());
  return installer;
});

/// 最新バージョン情報のプロバイダー
final latestVersionProvider = FutureProvider<VersionInfo?>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return await updateService.fetchLatestVersion();
});

/// 更新が利用可能かどうかのプロバイダー
final isUpdateAvailableProvider = FutureProvider<bool>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return await updateService.isUpdateAvailable();
});

/// 強制更新が必要かどうかのプロバイダー
final isForceUpdateRequiredProvider = FutureProvider<bool>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return await updateService.isForceUpdateRequired();
});

/// 現在のアプリバージョンのプロバイダー
final currentVersionProvider = FutureProvider<String>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return await updateService.getCurrentVersion();
});
