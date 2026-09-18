pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 9.x fuerza el DSL nuevo (ignora android.newDsl=false) y varios
    // plugins (file_picker, firebase_*, cloud_firestore) todavía no son
    // compatibles con él, causando fallos de build en cadena. AGP 8.7.x es
    // la última serie estable totalmente compatible con Flutter 3.44.8 y
    // con todos los plugins de este proyecto.
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // Necesario para que Android lea el archivo google-services.json y
    // conecte la app con el proyecto Firebase.
    id("com.google.gms.google-services") version "4.5.0" apply false
}

include(":app")
