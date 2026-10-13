plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit être appliqué après les plugins Android et Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.azizart"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // Syntaxe simplifiée pour le Kotlin DSL (équivalent à JavaVersion.VERSION_17.toString())
        jvmTarget = "17" 
    }

    defaultConfig {
        // Identifiant unique de votre application
        applicationId = "com.example.azizart"

        // CORRECTION IMPORTANTE : 
        // Firebase et les plugins modernes exigent au minimum l'API 21. 
        // L'API 23 est recommandée pour éviter les problèmes de "MultiDex".
        minSdk = 23 

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signature avec les clés de débogage temporairement pour que `flutter run --release` fonctionne.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}