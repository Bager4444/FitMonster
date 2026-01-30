plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fitmonster.app"
    compileSdk = 36  // Обновлено до версии 36 для совместимости с плагинами
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // FitMonster Application ID
        applicationId = "com.fitmonster.app"
        // Минимальная версия Android для ML Kit и Camera
        minSdk = flutter.minSdkVersion  // Android 5.0 для ML Kit
        targetSdk = 36  // Обновлено до версии 36
        versionCode = 1
        versionName = "1.0.0"
        
        // Поддержка многоязычности
        resConfigs("en", "ru")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
