pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Include Flutter's Gradle logic for plugin resolution
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Standard repositories for Gradle plugins
        google()
        mavenCentral()
        gradlePluginPortal() // Required for plugins like dev.flutter.flutter-plugin-loader
    }
}

// Declares plugins that are globally available and their versions.
// The actual 'apply' happens in the build.gradle.kts files (top-level and app-level).
plugins {
    // This plugin is loaded via pluginManagement's includeBuild and typically has a fixed version "1.0.0"
    // as part of the Flutter SDK integration.
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    
    // Declare the Android Application plugin version here.
    // The 'apply false' means it's declared available, but not applied to this settings file itself.
    id("com.android.application") version "8.10.1" apply false // Use your desired latest AGP version
    
    // Declare the Kotlin Android plugin version here.
    id("org.jetbrains.kotlin.android") version "2.1.21" apply false // Use your desired latest KGP version
}

// Include the 'app' module in the build
include(":app")
