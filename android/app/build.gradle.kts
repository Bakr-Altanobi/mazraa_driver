import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
// Use the developer's existing trial key without checking a credential into Git.
// CI/release signing may instead inject MAPS_API_KEY through the environment.
val mapsApiKey = localProperties.getProperty("MAPS_API_KEY")
    ?.takeIf { it.isNotBlank() }
    ?: System.getenv("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
    ?: ""

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// The CI arm64 release APK is a debug-signed *staging* artifact. Store
// distribution must never silently fall back to that signature. Flutter's
// appbundle release path is a publication build even without an extra flag.
val publishingDriver = System.getenv("DRIVER_PUBLISH_RELEASE")
    ?.equals("true", ignoreCase = true) == true ||
    gradle.startParameter.taskNames.any {
        it.endsWith("bundleRelease", ignoreCase = true)
    }
if (publishingDriver) {
    if (mapsApiKey.isBlank()) {
        throw GradleException(
            "Driver publication requires MAPS_API_KEY in android/local.properties or the environment."
        )
    }
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "Driver publication requires android/key.properties with a production keystore."
        )
    }
    val missing = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        throw GradleException("Incomplete release signing configuration: ${missing.joinToString()}")
    }
    if (!file(keystoreProperties.getProperty("storeFile")).isFile) {
        throw GradleException("The configured driver release keystore file does not exist.")
    }
}

android {
    namespace = "com.mazraa.driver"
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
        applicationId = "com.mazraa.driver"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
