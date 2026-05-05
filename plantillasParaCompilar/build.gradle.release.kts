/*
 * TEMPLATE: build.gradle.kts configurado para builds RELEASE (producción).
 * Destino: android/app/build.gradle.kts
 * App: CombisChiautempan
 *
 * CRÍTICO — no olvidar:
 *   - namespace DEBE coincidir con el path de MainActivity.kt:
 *       android/app/src/main/kotlin/mx/combis/combischiautempanrun/MainActivity.kt
 *   - applicationId y namespace deben ser idénticos: "mx.combis.combischiautempanrun"
 *   - Si Flutter generó el proyecto con "com.example.*", hay que:
 *       1) Cambiar namespace y applicationId aquí
 *       2) Mover MainActivity.kt al path correcto
 *       3) Ajustar AndroidManifest.xml con android:name=".MainActivity"
 *   - Para distribución real (Play Store / firmado): reemplazar signingConfigs.debug con key real.
 */

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
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
        minSdk = 34   // Android 12.0 — mínimo para unos metodos
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // PENDIENTE: Reemplazar con signing config real antes de distribuir
            // Ejemplo:
            //   signingConfig = signingConfigs.create("release") {
            //       keyAlias = "combis-release"
            //       keyPassword = System.getenv("KEY_PASS")
            //       storeFile = file("release-key.jks")
            //       storePassword = System.getenv("STORE_PASS")
            //   }
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false     // activar cuando se prueben reglas de ProGuard
            isShrinkResources = false   // depende de isMinifyEnabled
        }
    }
}

flutter {
    source = "../.."
}
