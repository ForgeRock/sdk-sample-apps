import java.util.Properties

group = "com.pingidentity.flutter.oidc"
version = "1.0-SNAPSHOT"

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutter injects `flutter.jar` onto the compile classpath automatically when it drives the
// build; standalone builds (Android Studio opened directly on this `android/` directory, or a
// bare `./gradlew` invocation) need it added explicitly for `PingOidcPlugin.kt`'s
// `io.flutter.embedding.engine.plugins.FlutterPlugin` import to resolve. Requires a
// `local.properties` with `flutter.sdk=<path>` (gitignored, per-developer).
val flutterSdkPath: String? by lazy {
    val localPropertiesFile = file("local.properties")
    if (localPropertiesFile.exists()) {
        val properties = Properties()
        localPropertiesFile.inputStream().use { stream -> properties.load(stream) }
        properties.getProperty("flutter.sdk")?.let { return@lazy it }
    }
    System.getenv("FLUTTER_ROOT")
}

android {
    namespace = "com.pingidentity.flutter.oidc"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 29
        manifestPlaceholders["appRedirectUriScheme"] = "com.pingidentity.flutter.oidc"
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                // Ping SDK 2.x artifacts are compiled for Java 21; running tests on an older
                // test JVM fails with UnsupportedClassVersionError at class-load time.
                it.javaLauncher.set(
                    javaToolchains.launcherFor {
                        languageVersion.set(JavaLanguageVersion.of(21))
                    }
                )

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    if (flutterSdkPath != null) {
        compileOnly(fileTree(mapOf("dir" to "$flutterSdkPath/bin/cache/artifacts/engine/android-arm", "include" to listOf("flutter.jar"))))
    }

    implementation(project(":ping_core"))
    implementation("com.pingidentity.sdks:oidc:2.1.0")
    implementation("com.pingidentity.sdks:browser:2.1.0")
    implementation("com.pingidentity.sdks:storage:2.1.0")
    implementation("com.pingidentity.sdks:orchestrate:2.1.0")
    implementation("com.pingidentity.sdks:android:2.1.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0")

    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.14.2")
}
