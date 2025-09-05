import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.reader())
}

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.warriorpath.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    // --- 1. AÑADIMOS ESTE BLOQUE PARA CARGAR LAS CLAVES ---
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties") // Apunta al archivo en la carpeta 'android'
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }
    // --------------------------------------------------------

    defaultConfig {
        applicationId = "com.warriorpath.app"
        minSdk = 23
        targetSdk = 35
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    // --- 2. AÑADIMOS ESTE BLOQUE PARA CONFIGURAR LA FIRMA ---
    signingConfigs {
        create("release") {
            val alias = keystoreProperties["keyAlias"]?.toString()
            val keyPass = keystoreProperties["keyPassword"]?.toString()
            val store = keystoreProperties["storeFile"]?.toString()
            val storePass = keystoreProperties["storePassword"]?.toString()

            println(">>> [Gradle] keyAlias=$alias, storeFile=$store")

            if (alias == null || keyPass == null || store == null || storePass == null) {
                throw GradleException("Alguna propiedad en key.properties falta o no se está leyendo correctamente")
            }

            keyAlias = alias
            keyPassword = keyPass
            storeFile = file(store)
            storePassword = storePass
        }
    }
    // ----------------------------------------------------------

    // --- 3. MODIFICAMOS ESTE BLOQUE PARA USAR LA FIRMA ---
    buildTypes {
        getByName("release") {
            // Esto le dice a la versión de lanzamiento que use la configuración de firma "release"
            signingConfig = signingConfigs.getByName("release")
        }
    }
    // ----------------------------------------------------

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(kotlin("stdlib-jdk8"))
}
