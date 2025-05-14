$pluginPath = "C:\Users\Uver Diaz\AppData\Local\Pub\Cache\hosted\pub.dev\record_android-1.3.2\android\build.gradle"

$content = @"
group 'com.llfbandit.record'
version '1.0'

buildscript {
    ext.kotlin_version = '1.8.21'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // https://developer.android.com/studio/releases/gradle-plugin
        classpath 'com.android.tools.build:gradle:8.5.2'
        // https://plugins.gradle.org/plugin/org.jetbrains.kotlin.android
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'
apply plugin: 'org.jetbrains.kotlin.android'

android {
    namespace 'com.llfbandit.record'

    // Add explicit compileSdkVersion instead of referencing flutter
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 23
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
"@

Set-Content -Path $pluginPath -Value $content

Write-Host "Plugin build.gradle file has been fixed." 