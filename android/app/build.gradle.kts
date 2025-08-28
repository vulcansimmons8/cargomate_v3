plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ import + read local.properties with providers
import com.android.build.gradle.internal.cxx.configure.gradleLocalProperties
val localProps = gradleLocalProperties(rootDir, providers)
val MAPS_API_KEY: String = localProps.getProperty("MAPS_API_KEY") ?: ""

android {
    namespace = "com.example.cargomate_v3"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // optional to silence your earlier NDK warning

    defaultConfig {
        applicationId = "com.example.cargomate_v3"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ expose the key to Android resources
        resValue("string", "google_maps_key", MAPS_API_KEY)
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
