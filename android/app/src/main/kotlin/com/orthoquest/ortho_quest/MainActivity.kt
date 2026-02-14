package com.orthoquest.ortho_quest

import android.app.WallpaperManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val channelName = "orthoquest/wallpaper"
    private val wallpaperExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaperFromFile" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?>
                    if (args != null) {
                        val filePath = args["filePath"] as? String
                        val location = (args["wallpaperLocation"] as? Number)?.toInt() ?: 3
                        if (filePath != null && File(filePath).exists()) {
                            wallpaperExecutor.execute {
                                try {
                                    val success = setWallpaperWithCorrectColors(filePath, location)
                                    runOnUiThread { result.success(success) }
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                    runOnUiThread { result.success(false) }
                                }
                            }
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Décode l'image et l'applique en fond d'écran sans altérer les couleurs.
     * - Pas de setPremultiplied(false) : le décodage Android utilise le format premultiplied
     *   par défaut ; le modifier pouvait provoquer un assombrissement au rendu.
     * - inSampleSize réduit la taille en mémoire pour accélérer le traitement sur gros fichiers.
     */
    private fun setWallpaperWithCorrectColors(filePath: String, location: Int): Boolean {
        return try {
            // Décoder les dimensions sans charger l'image entière
            val boundsOptions = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(filePath, boundsOptions)
            val w = boundsOptions.outWidth
            val h = boundsOptions.outHeight

            // Sous-échantillonner si l'image dépasse ~1080p (accélère beaucoup le traitement)
            var sampleSize = 1
            val maxDim = 1920
            while (w / sampleSize > maxDim || h / sampleSize > maxDim) {
                sampleSize *= 2
            }

            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inScaled = false
                inPreferredConfig = Bitmap.Config.ARGB_8888
                inDither = false
            }
            val bitmap = BitmapFactory.decodeFile(filePath, options) ?: return false
            val wm = WallpaperManager.getInstance(this)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                wm.setBitmap(bitmap, null, false, location)
            } else {
                wm.setBitmap(bitmap)
            }
            if (!bitmap.isRecycled) bitmap.recycle()
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }
}
