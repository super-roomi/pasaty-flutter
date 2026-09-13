import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase Cloud Messaging.
//
// Applied conditionally rather than in the `plugins` block above: the
// google-services plugin fails the whole build when google-services.json is
// absent, and that file is per-Firebase-project configuration that is not in
// the repository. Without it the app still builds and runs — Firebase simply
// fails to initialise and PushService degrades to "no push", which it is
// written to do. Drop the file in android/app/ and push starts working with
// no other change.
val googleServicesConfig = file("google-services.json")
if (googleServicesConfig.exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn(
        "google-services.json not found in android/app — building without " +
            "Firebase. Push notifications will be inactive on Android."
    )
}

// Release signing credentials live in android/key.properties, which is
// gitignored — the upload keystore must never be committed. When the file is
// absent (fresh clone, CI without secrets) the release build falls back to the
// debug key so `flutter run --release` still works locally; that fallback is
// blocked for real uploads by the `assertReleaseSigning` check below.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "iq.masaralburhan.app"
    // flutter_secure_storage compiles against SDK 37; staying on
    // flutter.compileSdkVersion (36) warns now and fails on newer AGP.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Permanent once the first build is uploaded to Play — it cannot be
        // changed afterwards without publishing a brand new listing.
        applicationId = "iq.masaralburhan.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Play rejects debug-signed artifacts. Fail the bundle task loudly rather than
// letting a debug-signed AAB get as far as an upload attempt.
tasks.matching { it.name == "bundleRelease" }.configureEach {
    doFirst {
        check(hasReleaseKeystore) {
            "Release signing is not configured. Create android/key.properties " +
                "with storeFile/storePassword/keyAlias/keyPassword before " +
                "building an upload bundle."
        }
    }
}

flutter {
    source = "../.."
}
