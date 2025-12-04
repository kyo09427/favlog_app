import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_compressor.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final imageCompressorProvider = Provider<ImageCompressor>((ref) => ImageCompressor());
