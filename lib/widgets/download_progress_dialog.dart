import 'package:flutter/material.dart';

/// ダウンロード進捗を表示するダイアログ
class DownloadProgressDialog extends StatelessWidget {
  /// ダウンロード進捗（0-100）
  final int progress;

  /// ステータスメッセージ
  final String status;

  /// エラーメッセージ（nullの場合はエラーなし）
  final String? error;

  /// エラー時の閉じるボタンコールバック
  final VoidCallback? onClose;

  const DownloadProgressDialog({
    super.key,
    required this.progress,
    required this.status,
    this.error,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return PopScope(
      // ダウンロード中は戻るボタンで閉じられないようにする
      canPop: hasError,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              hasError ? Icons.error : Icons.download,
              color: hasError ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              hasError ? 'エラー' : 'アップデート中',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasError) ...[
              // 進捗バー
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              // 進捗パーセンテージ
              Text(
                '$progress%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // ステータスメッセージ
            Text(
              hasError ? error! : status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: hasError ? Colors.red : Colors.grey.shade700,
              ),
            ),
            if (!hasError) ...[
              const SizedBox(height: 16),
              Text(
                'ダウンロードが完了するまでお待ちください',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: hasError && onClose != null
            ? [TextButton(onPressed: onClose, child: const Text('閉じる'))]
            : null,
      ),
    );
  }
}
