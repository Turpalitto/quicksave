# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Gson / JSON (if used by plugins)
-keepattributes Signature
-keepattributes *Annotation*

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# workmanager
-keep class be.tramckrijte.workmanager.** { *; }

# Keep native MainActivity / services
-keep class com.quicksave.app.** { *; }

# Flutter deferred components / Play Core (optional at runtime)
-dontwarn com.google.android.play.core.**
