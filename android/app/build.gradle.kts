plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // updated plugin ID to match new style
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.vibezone_flutter"
    compileSdk = 34 // ✅ Optional: Use latest stable if possible

    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.vibezone_flutter"
        minSdk = 21
        targetSdk = 34 // ✅ Match latest compileSdk if you're updating
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // ⚠️ Use release keystore for production!
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
