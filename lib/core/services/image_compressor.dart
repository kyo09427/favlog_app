import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

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

      // WebP形式でエンコード（JPEGにフォールバック）
      try {
        final encoded = img.encodeWebP(resized);
        return Uint8List.fromList(encoded);
      } catch (e) {
        // WebPエンコードに失敗したらJPEGを使用
        debugPrint('WebP encoding failed, using JPEG: \');
        return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      }
    } catch (e) {
      debugPrint('Error compressing image on web: \');
      return imageBytes;
    }
  }

  Future<Uint8List> _compressImageNative(
    Uint8List imageBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.webp,
      );
      return result;
    } catch (e) {
      debugPrint('Error compressing image on native: \');
      return imageBytes;
    }
  }
}
