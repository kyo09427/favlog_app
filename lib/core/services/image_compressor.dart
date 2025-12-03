import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// 画像圧縮サービスの抽象インターフェース
abstract class ImageCompressor {
  Future<Uint8List?> compressWithFile(String path, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    CompressFormat format = CompressFormat.jpeg,
  });
}

// flutter_image_compress を使用した具象実装
class FlutterImageCompressor implements ImageCompressor {
  @override
  Future<Uint8List?> compressWithFile(String path, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    CompressFormat format = CompressFormat.jpeg,
  }) {
    return FlutterImageCompress.compressWithFile(
      path,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: format,
    );
  }
}
