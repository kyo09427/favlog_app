import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';

/// APKのダウンロードとインストールを管理するサービス
class ApkInstaller {
  /// ダウンロード進捗のストリームコントローラー
  final _progressController = StreamController<int>.broadcast();

  /// ダウンロード状態のストリームコントローラー
  final _statusController = StreamController<String>.broadcast();

  /// エラーのストリームコントローラー
  final _errorController = StreamController<String>.broadcast();

  /// ダウンロード進捗のストリーム
  Stream<int> get progressStream => _progressController.stream;

  /// ダウンロード状態のストリーム
  Stream<String> get statusStream => _statusController.stream;

  /// エラーのストリーム
  Stream<String> get errorStream => _errorController.stream;

  /// APKをダウンロードしてインストール
  ///
  /// [downloadUrl] APKのダウンロードURL
  ///
  /// 戻り値: インストールが成功した場合true、失敗した場合false
  Future<bool> downloadAndInstall(String downloadUrl) async {
    try {
      _statusController.add('ダウンロードを開始しています...');

      // OTAアップデートを実行
      OtaUpdate()
          .execute(downloadUrl, destinationFilename: 'FavLog.apk')
          .listen(
            (OtaEvent event) {
              _handleOtaEvent(event);
            },
            onError: (error) {
              _handleError(error);
            },
          );

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// OTAイベントを処理
  void _handleOtaEvent(OtaEvent event) {
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        final progress = int.tryParse(event.value ?? '0') ?? 0;
        _progressController.add(progress);
        _statusController.add('ダウンロード中... $progress%');
        break;

      case OtaStatus.INSTALLING:
        _statusController.add('インストール中...');
        break;

      case OtaStatus.ALREADY_RUNNING_ERROR:
        _errorController.add('ダウンロードが既に実行中です');
        break;

      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        _errorController.add(
          'インストール権限が許可されていません。\n設定からこのアプリに「不明なアプリのインストール」を許可してください。',
        );
        break;

      case OtaStatus.INTERNAL_ERROR:
        _errorController.add('内部エラーが発生しました: ${event.value}');
        break;

      case OtaStatus.DOWNLOAD_ERROR:
        _errorController.add('ダウンロードに失敗しました: ${event.value}');
        break;

      case OtaStatus.CHECKSUM_ERROR:
        _errorController.add('ファイルの検証に失敗しました');
        break;

      default:
        if (kDebugMode) {
          print('OTA Event: ${event.status} - ${event.value}');
        }
    }
  }

  /// エラーを処理
  void _handleError(dynamic error) {
    String errorMessage = 'アップデートに失敗しました';

    if (error is Exception) {
      errorMessage = error.toString();
    } else if (error is String) {
      errorMessage = error;
    }

    _errorController.add(errorMessage);
    _statusController.add('エラー: $errorMessage');
  }

  /// リソースをクリーンアップ
  void dispose() {
    _progressController.close();
    _statusController.close();
    _errorController.close();
  }
}
