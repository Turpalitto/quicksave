import 'dart:io';

import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';

/// Сохранение файлов в системную Gallery (MediaStore на Android).
class GallerySaveService {
  GallerySaveService._();
  static final GallerySaveService instance = GallerySaveService._();

  static const MethodChannel _channel = MethodChannel(
    AppConstants.galleryChannelName,
  );

  /// Копирует [filePath] в Gallery. Возвращает URI или исходный путь.
  Future<String> saveToGallery(String filePath, {required bool isVideo}) async {
    if (!Platform.isAndroid) return filePath;
    try {
      final uri = await _channel.invokeMethod<String>('saveToGallery', {
        'path': filePath,
        'isVideo': isVideo,
      });
      return uri ?? filePath;
    } catch (_) {
      return filePath;
    }
  }
}
