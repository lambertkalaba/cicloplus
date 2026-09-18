import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Lee google-services.json y genera la configuración que Firebase necesita.
    id("com.google.gms.google-services")
}

// Firma de producción: lee las credenciales desde android/key.properties
// (archivo NO versionado, ver .gitignore) en vez de tenerlas escritas
// directamente aquí. Si el archivo no existe (por ejemplo en un clon
// nuevo del proyecto sin el keystore todavía), el build de debug sigue
// funcionando igual; solo `flutter build appbundle --release` lo necesita.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.cicloplus.cicloplus_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cicloplus.cicloplus_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Health Connect (sincronización con Google Fit) requiere Android 8
        // (API 26) como mínimo; se fija explícitamente en vez de usar el
        // valor por defecto de Flutter, que es más bajo.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            // Firma con la clave de producción (android/cicloplus-release-key.jks)
            // si key.properties existe; si no, recae en la firma de debug para
            // que `flutter run --release` siga funcionando en desarrollo.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Firebase BoM: fija versiones compatibles entre sí para todos los
    // paquetes de Firebase que usemos, así no hay que elegir versiones a mano.
    implementation(platform("com.google.firebase:firebase-bom:34.17.0"))
}

// Mismo problema que ya se documentó en pubspec.yaml junto a `health` y
// `url_launcher`: al añadir image_picker (fotos del chat con el socio,
// ver partner_chat_screen.dart) Gradle intenta resolver versiones muy
// recientes de androidx.core/androidx.activity que exigen AGP 8.9.1+ — y
// AGP sigue fijado en 8.7.3 aparte para no romper esos otros paquetes. En
// vez de mover AGP (arriesgaría reabrir esos conflictos ya resueltos),
// fijamos aquí las últimas versiones de estas librerías androidx todavía
// compatibles con AGP 8.7.3.
// (Se probó también a añadir mobile_scanner aquí para escanear QR con la
// cámara — necesitó forzar androidx.camera a 1.4.2 por el mismo motivo
// de arriba, y aun así la app se quedaba colgada en el splash con un
// error de canal de shared_preferences_android al arrancar. Se quitó
// mobile_scanner de pubspec.yaml; si se retoma, revisar ese historial.)
configurations.all {
    resolutionStrategy {
        force("androidx.core:core-ktx:1.16.0")
        force("androidx.core:core:1.16.0")
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.activity:activity:1.9.3")
    }
}
flutter {
    source = "../.."
}