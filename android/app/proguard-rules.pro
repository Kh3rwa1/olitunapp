# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Just Audio & Audio Service (ExoPlayer & Media3 bundle consumer rules)
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
-dontwarn androidx.media.**
-dontwarn com.ryanheise.**

# Sentry (bundles official consumer rules in sentry-android-core)
-dontwarn io.sentry.**

# Google Play Core & GMS (Flutter engine references these)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**

# Flutter Local Notifications & GSON
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}
-dontwarn com.google.gson.**

# Allow obfuscation of most things, but keep some essentials
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
