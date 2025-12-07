import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

// 画像圧縮サービスクラス
// プラットフォーム（Web/ネイティブ）に応じて内部で処理を切り替える
// すべての画像をWebP形式で圧縮（Windows/LinuxはJPEGフォールバック）
class ImageCompressor {
  Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    // Windows/Linux/Fuchsiaはflutter_image_compressが非対応のためimageパッケージを使用
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isFuchsia)) {
      return _compressWithImageLibrary(imageBytes, maxWidth, maxHeight, quality);
    } else {
      // Web, Android, iOS, macOSはflutter_image_compressを使用（WebP有効）
      return _compressImageNative(imageBytes, maxWidth, maxHeight, quality);
    }
  }

  Future<Uint8List> _compressWithImageLibrary(
    Uint8List imageBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) async {
    try {
      return await compute(
        _libraryCompressionTask,
        _CompressionParams(imageBytes, maxWidth, maxHeight, quality),
      );
    } catch (e) {
      debugPrint('Error compressing image with library: $e');
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
        format: CompressFormat.webp,
      );
      return result;
    } catch (e) {
      debugPrint('Error compressing image on native/web: $e');
      return imageBytes; // 圧縮に失敗した場合は元のバイトデータを返す
    }
  }
}

class _CompressionParams {
  final Uint8List bytes;
  final int maxWidth;
  final int maxHeight;
  final int quality;

  _CompressionParams(this.bytes, this.maxWidth, this.maxHeight, this.quality);
}

Future<Uint8List> _libraryCompressionTask(_CompressionParams params) async {
  final image = img.decodeImage(params.bytes);
  if (image == null) return params.bytes;

  final resized = img.copyResize(
    image,
    width: params.maxWidth,
    height: params.maxHeight,
    maintainAspect: true,
  );

  // Windows/Linux版ではWebPエンコードが利用できないためJPEGを使用（PNGより軽量）
  // 品質はparams.qualityを使用
  return Uint8List.fromList(img.encodeJpg(resized, quality: params.quality));
}
