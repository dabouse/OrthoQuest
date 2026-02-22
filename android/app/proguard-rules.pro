## Flutter-specific ProGuard rules

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep plugin registrants
-keep class io.flutter.plugins.** { *; }

# Keep Google Fonts
-keep class com.google.android.gms.** { *; }

# Suppress warnings for common Flutter dependencies
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.**
