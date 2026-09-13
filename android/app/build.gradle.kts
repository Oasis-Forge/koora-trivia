import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // يجب تطبيق إضافة Flutter بعد إضافتي Android و Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

// مفتاح التوقيع للإصدار: يُقرأ من android/key.properties خارج Git.
// إن غاب الملف يعود البناء لمفتاح التصحيح (للتطوير على جهاز بلا المفتاح).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.oasisforge.kooratrivia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // مطلوب لحزمة flutter_local_notifications — بدونه يفشل البناء.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.oasisforge.kooratrivia"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // يُنشأ فقط عند وجود key.properties — وإلا نبقى على التصحيح.
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // يوقّع بمفتاح الإصدار إن توفّر key.properties، وإلا بمفتاح التصحيح.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // نُطفئ R8 (التصغير والإخفاء) في الإصدار عمداً: AGP 9 يفعّله افتراضياً،
            // فيُعيد تسمية أصناف Room المولّدة (WorkDatabase_Impl) التي تحمّلها
            // مكتبة WorkManager عبر الانعكاس (يجلبها SDK إعلانات AdMob لإرسال
            // نبضات دون اتصال) ⇒ تعطّل التطبيق فور الإقلاع في بناء الإصدار فقط.
            // إخفاء تطبيق أسئلة لا قيمة كبيرة له، والإطفاء يضمن عمل الانعكاس.
            isMinifyEnabled = false
            isShrinkResources = false
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
}

flutter {
    source = "../.."
}
