/*
 * TEMPLATE: build.gradle.kts configurado para builds DEBUG (desarrollo local / Waydroid).
 * Destino: android/app/build.gradle.kts
 * App: CombisChiautempan
 *
 * Igual que el release pero con:
 *   - isMinifyEnabled / isShrinkResources explícitamente apagados (son el default, pero lo dejo
 *     documentado para que si alguien mueve esto a release no lo active por accidente).
 *   - Debug signing siempre usado — no se requiere keystore real.
 *   - Comentario resaltando que applicationId y namespace deben coincidir con el path de
 *     MainActivity.kt bajo android/app/src/main/kotlin/mx/combis/combischiautempanrun/.
 */

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // IMPORTANTE: namespace debe coincidir con el path de MainActivity.kt
    namespace = "mx.combis.combischiautempanrun"
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
        applicationId = "mx.combis.combischiautempanrun"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // Dev-friendly: firma con debug para que `flutter run --release` funcione sin keystore.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
