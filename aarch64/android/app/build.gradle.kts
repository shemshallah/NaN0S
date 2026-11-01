plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "org.nan0s.vm"
    compileSdk = 34

    defaultConfig {
        applicationId = "org.nan0s.vm"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "0.4"
        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64") }
        externalNativeBuild { cmake { arguments += listOf("-DANDROID_STL=none") } }
    }
    externalNativeBuild { cmake { path = file("src/main/cpp/CMakeLists.txt"); version = "3.22.1" } }
    buildTypes { release { isMinifyEnabled = false } }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
    // the image is stored uncompressed-friendly: it is 1.4 MB, mostly zeros
    androidResources { noCompress += "img" }
}

// Optional: refresh the bundled image from the x86 build (sh x86/tools/mkall.sh -> x86/build/nan0s.img). This project lives at <repo>/aarch64/android/.
tasks.register<Copy>("syncImage") {
    from("../../../x86/build/nan0s.img")
    into("src/main/assets")
    onlyIf { file("../../../x86/build/nan0s.img").exists() }
}
