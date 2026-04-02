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

## flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

## file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

## share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

## permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

## local_auth
-keep class io.flutter.plugins.localauth.** { *; }

## QR scanner
-keep class com.journeyapps.barcodescanner.** { *; }
-keep class com.google.zxing.** { *; }

## Keep model classes for JSON serialization
-keep class com.vaultnote.vaultnote.domain.entities.** { *; }
