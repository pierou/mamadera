plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing configuration
// Reads keystore details from environment variables (set in CI or local env):
//   KEYSTORE_PATH  — path to the .jks/.keystore file (absolute path recommended)
//   KEYSTORE_PASSWORD — password for the keystore
//   KEY_ALIAS      — alias of the key inside the keystore
//   KEY_PASSWORD   — password for the individual key
val keystorePath = System.getenv("KEYSTORE_PATH")
val hasReleaseSigning = !keystorePath.isNullOrEmpty() && file(keystorePath).exists()

android {
    namespace = "com.pvjio.mamadera"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.pvjio.mamadera"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(System.getenv("KEYSTORE_PATH"))
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
                keyAlias = System.getenv("KEY_ALIAS") ?: ""
                keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            }
        }
    }

    buildTypes {
        release {
            // No debug fallback on purpose: without a keystore the release
            // variant is left unsigned and the guard below fails the build
            // with an actionable error (see taskGraph hook at the bottom).
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

// Fail fast instead of silently falling back to debug signing:
// a "release" build without the release keystore would produce a
// debug-signed APK that looks like a production build.
gradle.taskGraph.whenReady {
    val releaseBuildRequested =
        allTasks.any { it.name == "assembleRelease" || it.name == "bundleRelease" }
    if (releaseBuildRequested && !hasReleaseSigning) {
        throw GradleException(
            "Release build requested but the release keystore is not configured.\n"
                + "Set the following environment variables and re-run:\n"
                + "  KEYSTORE_PATH      path to the .jks/.keystore file\n"
                + "  KEYSTORE_PASSWORD  password for the keystore\n"
                + "  KEY_ALIAS          key alias inside the keystore\n"
                + "  KEY_PASSWORD       password for the key\n"
                + "Refusing to fall back to debug signing for a release build."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
