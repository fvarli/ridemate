import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────
// Release signing — FAIL CLOSED.
//
// A release artifact must never be signed with the debug key. Debug keys are
// shared, checked into every Flutter install, and an app signed with one can
// be impersonated by anyone; a build that quietly falls back to them is worse
// than a build that fails, because nothing downstream can tell the difference.
//
// So there is no fallback. Either android/key.properties supplies a real
// upload key, or a requested release build stops at configuration time with an
// actionable message. Debug builds are untouched and need no private material.
//
// key.properties and every keystore form are git-ignored, at the repository
// root and under android/. Nothing here generates a key or invents a password.
// ─────────────────────────────────────────────────────────────

val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()

val keystoreProperties = Properties().apply {
    if (hasReleaseSigning) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

// Escape hatch for structural verification only: produces a deliberately
// unsigned release artifact. It is an explicitly named path, never the default,
// so "release build succeeded" can never quietly mean "unsigned".
val allowUnsignedRelease =
    (project.findProperty("ridemate.allowUnsignedRelease") as String?) == "true"

// Fires only when a release task is actually requested, so debug builds and
// plain `flutter pub get` are unaffected.
val releaseTaskRequested = gradle.startParameter.taskNames.any { it.contains("Release") }

if (releaseTaskRequested && !hasReleaseSigning && !allowUnsignedRelease) {
    throw GradleException(
        """
        |
        |RideMate: refusing to build a release artifact without a release signing key.
        |
        |There is deliberately no debug-key fallback. To sign a release build,
        |create android/key.properties (git-ignored, never committed) containing:
        |
        |    storeFile=/absolute/path/to/upload-keystore.jks
        |    storePassword=…
        |    keyAlias=upload
        |    keyPassword=…
        |
        |See docs/release/RELEASE_IDENTITY.md for how the upload key is created
        |and where it must be kept.
        |
        |To produce a deliberately UNSIGNED artifact for structural testing only:
        |
        |    flutter build apk --release -Pridemate.allowUnsignedRelease=true
        |
        |That artifact cannot be installed as an update or uploaded to Play.
        |
        """.trimMargin()
    )
}

android {
    namespace = "com.lunexa.ridemate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Permanent after first publish. See docs/release/RELEASE_IDENTITY.md.
        applicationId = "com.lunexa.ridemate"
        // minSdk/targetSdk are inherited from the Flutter SDK on purpose: the
        // generated values are the intended baseline and RELEASE_IDENTITY.md
        // records the decision not to override them natively.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Only ever the release config. When it does not exist the build has
            // already failed above, unless an unsigned artifact was explicitly
            // requested — in which case leaving this null is the honest result.
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
        }
    }
}

flutter {
    source = "../.."
}
