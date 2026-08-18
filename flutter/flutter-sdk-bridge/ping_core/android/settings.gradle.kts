pluginManagement {
    // Versions declared here only take effect when this module is opened/built as the root of
    // its own standalone build (Android Studio opened directly on this directory, or a bare
    // `./gradlew`). When included as a subproject of a consuming Flutter app's build, that
    // build's own settings.gradle.kts governs plugin resolution instead — this block is never
    // consulted, so it can't conflict with the version already resolved there.
    plugins {
        id("com.android.library") version "9.0.1"
        id("org.jetbrains.kotlin.android") version "2.3.20"
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = "ping_core"
