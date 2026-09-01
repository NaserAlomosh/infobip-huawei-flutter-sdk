plugins {
    id("com.android.library") version "8.13.0"
    id("org.jetbrains.kotlin.android") version "2.1.0"
}

group = "com.infobip.mobilemessaging.huawei"
version = "0.1.0"

android {
    namespace = "com.infobip.mobilemessaging.huawei"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
        targetSdk = 36
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

repositories {
    google()
    mavenCentral()
    maven("https://developer.huawei.com/repo/")
}

dependencies {
    implementation("com.infobip:infobip-mobile-messaging-huawei-sdk:8.14.0@aar") {
        isTransitive = true
    }
    implementation("com.infobip:infobip-mobile-messaging-huawei-inbox-sdk:8.14.0@aar") {
        isTransitive = true
    }
    implementation("com.infobip:infobip-mobile-messaging-huawei-chat-sdk:8.14.0@aar") {
        isTransitive = true
    }
}
