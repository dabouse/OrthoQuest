import 'dart:io';

/// Indique si la définition de fond d'écran est supportée (Android uniquement).
bool get isWallpaperSupported => Platform.isAndroid;
