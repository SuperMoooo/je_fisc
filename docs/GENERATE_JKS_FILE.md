# Android Release Signing (JKS)

## 1. Generate the keystore

```bash
keytool -genkeypair -v -keystore my-release-key.jks -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
```

> ⚠️ Never commit the `.jks` file — the moarch-generated `.gitignore` rules
> already cover `*.jks` and `android/key.properties`. Store the keystore and
> its passwords in a password manager; losing it means you can never update
> the app on Google Play again.

Place the keystore in `android/app/` so `storeFile` can be a plain filename
(this matches what the build_apk workflow does in CI).

## 2. Create `android/key.properties`

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=my-key-alias
storeFile=my-release-key.jks
```

## 3. Wire it into `android/app/build.gradle.kts`

The `Properties`/`FileInputStream` imports at the top are required:

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // Only add this line if the project uses Firebase:
    // id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...existing config...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as? String
            keyPassword = keystoreProperties["keyPassword"] as? String
            storeFile = (keystoreProperties["storeFile"] as? String)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as? String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

## 4. Get the certificate SHA fingerprints

Needed for Firebase, Google Sign-In, deep links, etc.:

```bash
keytool -list -v -keystore my-release-key.jks -alias my-key-alias
```
