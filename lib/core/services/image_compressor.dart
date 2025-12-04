import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

// 画像圧縮サービスクラス
// プラットフォーム（Web/ネイティブ）に応じて内部で処理を切り替える
class ImageCompressor {
  Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    if (kIsWeb) {
      return _compressImageWeb(imageBytes, maxWidth, maxHeight, quality);
    } else {
      return _compressImageNative(imageBytes, maxWidth, maxHeight, quality);
    }
  }

  Future<Uint8List> _compressImageWeb(
    Uint8List imageBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      final resized = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        maintainAspect: true,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    } catch (e) {
      debugPrint('Error compressing image on web: $e');
      return imageBytes; // 圧縮に失敗した場合は元のバイトデータを返す
    }
  }

  Future<Uint8List> _compressImageNative(
    Uint8List imageBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) async {
    try {
      // flutter_image_compress は Uint8List を受け取る compressWithList を提供している
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      debugPrint('Error compressing image on native: $e');
      return imageBytes; // 圧縮に失敗した場合は元のバイトデータを返す
    }
  }
}