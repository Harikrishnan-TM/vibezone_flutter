pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Include Flutter tools Gradle plugin
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    // Define repositories for plugin resolution
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Apply the Flutter plugin loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Apply the Android plugin (version 8.7.0)
    id("com.android.application") version "8.7.0" apply false
    // Apply Kotlin plugin (version 1.8.22)
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

// Include the main app module
include(":app")

// Optional: Set the root project name
rootProject.name = "vibezone_flutter"
