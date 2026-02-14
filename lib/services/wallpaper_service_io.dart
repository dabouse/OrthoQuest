import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_handler/wallpaper_handler.dart';

const _channel = MethodChannel('orthoquest/wallpaper');

Future<bool> setWallpaperFromAssetPreservingColors(
  String assetPath,
  WallpaperLocation location,
) async {
  if (!Platform.isAndroid) return false;
  try {
    final data = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final ext = assetPath.split('.').last;
    final file = File('${tempDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    try {
      final result = await _channel.invokeMethod<bool>(
        'setWallpaperFromFile',
        {
          'filePath': file.path,
          'wallpaperLocation': location.index + 1,
        },
      );
      return result ?? false;
    } finally {
      if (await file.exists()) file.deleteSync();
    }
  } catch (_) {
    return false;
  }
}
