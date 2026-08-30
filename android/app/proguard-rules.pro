# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Custom ProGuard rules for your app
-keep class com.ol.itun.** { *; }

# Just Audio, Audio Service & ExoPlayer (Media3)
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-keep class androidx.media.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
-dontwarn com.ryanheise.**

# Razorpay & Sentry
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Google Play Core & GMS (Flutter engine references these)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**

# Allow obfuscation of most things, but keep some essentials
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
