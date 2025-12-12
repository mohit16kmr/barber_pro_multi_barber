import java.util.Properties
import java.io.FileInputStream

plugins {
    // Android application plugin is required by the Flutter Gradle plugin.
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // Google Services plugin temporarily disabled — re-enable when a matching
    // `android/app/google-services.json` is available for `com.example.barberpro`.
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.barberpro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable core library desugaring for libraries that require newer Java APIs
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.barberpro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions.add("flavor")

    productFlavors {
        create("customer") {
            dimension = "flavor"
            applicationId = "com.barberpro.customer"
            resValue("string", "app_name", "Barber Customer")
        }
        create("barber") {
            dimension = "flavor"
            applicationId = "com.barberpro.barber"
            resValue("string", "app_name", "Barber Shop")
        }
        create("admin") {
            dimension = "flavor"
            applicationId = "com.barberpro.admin"
            resValue("string", "app_name", "Barber Admin")
        }
    }

    // Load signing properties if present (android/key.properties)
    val keystorePropertiesFile = rootProject.file("android/key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: ""
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring library required by some plugins (e.g., flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
