// Import conditionnel : sur plateformes avec dart:io (Android, iOS, etc.)
// on utilise la version io, sinon (web) la version stub.
export 'wallpaper_utils_stub.dart'
    if (dart.library.io) 'wallpaper_utils_io.dart';
