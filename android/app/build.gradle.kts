// ✅ CRITICAL: Required imports for signing configuration
import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseSigningConfigured = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword"
).all { (keystoreProperties[it] as String?)?.isNotBlank() == true }

val allowDebugReleaseSigning =
    providers.gradleProperty("allowDebugReleaseSigning").orNull == "true" ||
    providers.environmentVariable("ALLOW_DEBUG_RELEASE_SIGNING").orNull == "true" ||
    providers.environmentVariable("ORG_GRADLE_PROJECT_allowDebugReleaseSigning").orNull == "true" ||
    System.getenv("ALLOW_DEBUG_RELEASE_SIGNING") == "true" ||
    System.getenv("ORG_GRADLE_PROJECT_allowDebugReleaseSigning") == "true"

android {
    namespace = "com.ol.itun"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ol.itun"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // ✅ Optimization: Enable shrinking, obfuscation, and optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            signingConfig = if (releaseSigningConfigured) {
                signingConfigs.getByName("release")
            } else if (allowDebugReleaseSigning) {
                logger.warn(
                    "Release signing config is missing (key.properties not found); " +
                        "explicit ALLOW_DEBUG_RELEASE_SIGNING enabled for CI build verification."
                )
                signingConfigs.getByName("debug")
            } else {
                throw GradleException(
                    "Production release build failed: key.properties is missing or incomplete.\n" +
                    "Production APK/AAB release builds must be cryptographically signed with release keystore credentials.\n" +
                    "For CI/local build verification only, pass -PallowDebugReleaseSigning=true or set environment variable ALLOW_DEBUG_RELEASE_SIGNING=true."
                )
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.10.0")
    implementation("androidx.core:core-ktx:1.15.0")
}

flutter {
    source = "../.."
}
