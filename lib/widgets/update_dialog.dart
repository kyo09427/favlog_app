import 'package:flutter/material.dart';
import '../models/version_info.dart';

/// アップデート通知ダイアログ
///
/// 新しいバージョンが利用可能な場合に表示されます。
class UpdateDialog extends StatelessWidget {
  /// バージョン情報
  final VersionInfo versionInfo;

  /// 強制更新フラグ
  final bool isForceUpdate;

  /// 「今すぐ更新」ボタンが押されたときのコールバック
  final VoidCallback onUpdate;

  /// 「後で」ボタンが押されたときのコールバック（強制更新時は表示されない）
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.isForceUpdate,
    required this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 強制更新の場合は戻るボタンで閉じられないようにする
      canPop: !isForceUpdate,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              isForceUpdate ? Icons.warning : Icons.system_update,
              color: isForceUpdate ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              isForceUpdate ? '重要なアップデート' : '新しいバージョン',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'バージョン ${versionInfo.version} が利用可能です',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (isForceUpdate)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'このアップデートは必須です。\n続行するには更新してください。',
                          style: TextStyle(fontSize: 14, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isForceUpdate) const SizedBox(height: 16),
              if (versionInfo.releaseNotes.isNotEmpty) ...[
                const Text(
                  '更新内容:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    versionInfo.releaseNotes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!isForceUpdate && onLater != null)
            TextButton(onPressed: onLater, child: const Text('後で')),
          ElevatedButton(
            onPressed: onUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: isForceUpdate ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('今すぐ更新'),
          ),
        ],
      ),
    );
  }
}
