## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Flutter embedding
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }

## Play Store split - keep classes
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**

## Keep crypto classes
-keep class com.vaultnote.vaultnote.core.crypto.** { *; }
