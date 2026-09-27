
# Flutter App Store Security Checklist
> Based on [OWASP Mobile Top 10 (2024)](https://owasp.org/www-project-mobile-top-10/)

Use this checklist before publishing a Flutter app to the Google Play Store or Apple App Store. Each section maps to an OWASP Mobile risk.

Anything already ticked is what `moarch init` generated. Those lines are kept
rather than dropped so the mapping to OWASP stays complete and you can tell
"handled" from "never considered" — everything unticked is yours. Items that
depend on an option you may not have selected say so.

---

## M1 — Improper Credential Usage

Secrets and credentials must never be hardcoded or bundled in the binary.

- [x] Secrets are read through `envied`, not hardcoded — `config/env/app_env.dart`
- [x] `.env` and the generated `config/env/app_env.g.dart` are both in
      `.gitignore`
- [x] The environment is injected at CI time — every generated workflow writes
      `.env` from `secrets.BASE_URL` and runs `build_runner` before it builds
- [x] Leaked secrets are scanned for on every push — the `secrets` job in
      `unified_workflow.yml`
- [ ] `.env.example` committed with dummy values, so a fresh clone can see
      which keys it needs. `init` writes `.env`, not the example — copy it and
      blank the values
- [ ] `google-services.json` / `GoogleService-Info.plist` handled on purpose.
      They are deliberately *not* in the generated `.gitignore`: they hold
      client identifiers rather than server secrets, and most projects commit
      them. Decide, rather than defaulting
- [ ] Anything genuinely sensitive fetched from your backend at runtime instead
      of being compiled in at all — `obfuscate: true` raises the cost of
      pulling a value out of the binary, it does not make it impossible

**What the scaffold generates — `lib/config/env/app_env.dart`:**

`envied` reads `.env` at code-generation time and bakes obfuscated values into
the binary, so no `.env` file is bundled or shipped.

```dart
import 'package:envied/envied.dart';

part 'app_env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract final class AppEnv {
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static final String baseUrl = _AppEnv.baseUrl;

  // Copy this pattern for additional environment values.
}
```

```bash
# Regenerate app_env.g.dart after every .env change
dart run build_runner build --delete-conflicting-outputs
```

> ⚠️ `app_env.g.dart` holds the compiled values and is gitignored, so it does
> not travel with a clone. That is why every generated workflow recreates `.env`
> from GitHub secrets and re-runs `build_runner` before `flutter build`.

**Packages:** [`envied`](https://pub.dev/packages/envied), [`envied_generator`](https://pub.dev/packages/envied_generator), [`build_runner`](https://pub.dev/packages/build_runner)

---

## M2 — Inadequate Supply Chain Security

Third-party packages can introduce vulnerabilities into your app.

- [x] CVEs gate the build — `osv-scan` runs on every push and
      `dependency-review` on every PR (`unified_workflow.yml`)
- [x] An SBOM (CycloneDX) and a `pana` license/health report are produced
      weekly and on every `v*` tag (`csa.yml`)
- [ ] `pubspec.lock` committed, so every machine and every CI run resolves the
      same versions
- [ ] New dependencies reviewed before adding — pub.dev score, publisher, last
      publish date
- [ ] `flutter pub outdated` run **and acted on** before each release; the CI
      jobs report, they do not upgrade
- [ ] No unused or abandoned packages left in `pubspec.yaml`
- [ ] Native dependencies (CocoaPods, Gradle) reviewed too — the scanners above
      only see the Dart graph

**Example — audit dependencies:**
```bash
flutter pub outdated
flutter pub upgrade --major-versions  # review breaking changes manually
```

---

## M3 — Insecure Authentication & Authorization

Authentication logic must be robust and not bypassable on the client side.

- [x] Biometrics go through the OS API — `core/security/biometric_service.dart`
      wraps `local_auth`, and `AppButton` gates a press on it through
      `beforePressed` (biometric option)
- [x] Tokens are refreshed rather than re-prompted — the Dio interceptor
      refreshes on a 401, replays the original request once, and signs the user
      out if the refresh itself fails (REST auth feature)
- [x] Logout clears the stored session — `TokenStorage.clearSession()` drops the
      access token, refresh token and user id
- [ ] The **server** invalidates the refresh token on logout too — clearing it
      on the device only stops that device from using it
- [ ] Authentication enforced server-side, never only on the client
- [ ] Access tokens genuinely short-lived; no client can make a long-lived
      token safe
- [ ] Role/permission checks on the backend, not in the Flutter UI — a hidden
      widget is not a permission check

**Example — the generated biometric gate:**
```dart
// Returns false and shows a snackbar on failure, so callers only need the bool.
final ok = await getIt<BiometricService>().verifyUserLocalAuth(context);
if (!ok) return;
```

**Packages:** [`local_auth`](https://pub.dev/packages/local_auth), [`firebase_auth`](https://pub.dev/packages/firebase_auth)

---

## M4 — Insufficient Input & Output Validation

All input entering or leaving the app must be validated and sanitised.

- [x] Form fields are validated client-side — `ValidationService` checks a
      value against an `InputType` and returns the cleaned form; `AppInput`
      calls it for you
- [x] Control characters, markup in free text, path traversal in file paths and
      non-http(s) URLs are rejected by that service rather than by each form
- [ ] The same rules enforced server-side. Client validation is UX; the server
      is the boundary
- [ ] No user input interpolated into SQL or shell commands — use parameterised
      queries. `ValidationService` deliberately does **not** blocklist SQL
      keywords: `O'Brien` is a name
- [ ] Deep link / URL parameters validated before use — routes are entry points
      an attacker controls
- [ ] Data from APIs, QR codes and NFC sanitised before it is rendered
- [ ] Anything rendered into a WebView escaped with
      `ValidationService.escapeHtml` — at the point you build the HTML, never
      on the way into storage

**Example — validating outside a form:**
```dart
final result = ValidationService.validate(raw, inputType: InputType.email);
if (!result.isValid) return showError(result.error!);
final email = result.sanitizedValue;
```

---

## M5 — Insecure Communication

All network traffic must be encrypted and verified.

- [x] Self-signed certificates are not accepted in production — the generated
      `dio_client.dart` installs its `badCertificateCallback` override inside an
      `if (kDebugMode)`, so a release build keeps full chain verification
- [ ] `BASE_URL` is `https://` in the production `.env` — nothing in the
      scaffold enforces the scheme for you
- [ ] Certificate pinning for sensitive endpoints — `_configureHttpClient` in
      `dio_client.dart` is the hook; see below
- [ ] Cleartext traffic disabled on Android (not generated — two steps below)
- [ ] iOS `NSAppTransportSecurity` does not allow arbitrary loads. `init` does
      not add the key, and ATS is on by default — only check this if you or a
      plugin added `NSAllowsArbitraryLoads`

**Example — certificate pinning, in the generated client:**
```dart
// core/network/dio_client.dart — replace the body of _configureHttpClient
import 'dart:io';

import 'package:dio/io.dart';

// Trust ONLY your server's certificate (bundle the .pem as an asset):
final context = SecurityContext(withTrustedRoots: false)
  ..setTrustedCertificatesBytes(certBytes);

dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () => HttpClient(context: context),
);
```

> Pinning breaks the app the day the certificate rotates. Pin to the CA or to a
> backup key you control, and ship a way to turn it off.

**Packages:** [`dio`](https://pub.dev/packages/dio), [`http_certificate_pinning`](https://pub.dev/packages/http_certificate_pinning)

**Android — disabling cleartext traffic.** `init` does not write this; add both
halves or neither, since the attribute alone is ignored on newer API levels.

1. `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="false" />
</network-security-config>
```

2. Point the manifest at it, in `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config"
    ... >
```

> Do this last. It also blocks a local `http://10.0.2.2` dev backend, so keep a
> debug-only override (`res/xml/network_security_config_debug.xml` referenced
> from a debug manifest) if you have one.

---

## M6 — Inadequate Privacy Controls

Apps must handle personal data with care and comply with GDPR / App Store privacy requirements.

- [x] Personal data is not logged in release builds — the generated logger
      drops debug/trace below `Level.warning` and redacts credentials at the
      sink
- [x] Permissions are requested at runtime, not assumed —
      `core/services/permission_service.dart`, with the media service asking
      only when it actually needs the camera or the library
- [x] Only the permissions your options need are compiled in — the generated
      `ios/Podfile` narrows `permission_handler` to camera and photos, instead
      of building every group and inheriting their usage-description
      requirements
- [ ] The manifest and `Info.plist` reviewed for permissions a *plugin* pulled
      in that you do not actually use
- [ ] Analytics and crash reporting configured not to collect PII — Crashlytics
      records what you pass it
- [ ] Privacy policy linked both in the store listing and inside the app
- [ ] Account deletion reachable from the UI (required by both stores). The
      generated auth feature has the call — REST `delete`, or Firebase account
      deletion — but no screen points at it
- [ ] Data Safety (Play) and the privacy nutrition label (App Store) filled in
      to match what the app really collects

**Example — what the generated `core/utils/app_logger.dart` already does:**
```dart
// Debug and trace records are stripped from release builds; warnings and
// errors survive so a crash report has context. Level.off silences release
// builds completely.
level: kReleaseMode ? Level.warning : Level.trace,
```

Credentials are redacted at the sink, so no call site has to remember to strip
them — `password`, `token`, `accessToken`, `refreshToken` and `Bearer …` values
are replaced with `***REDACTED***` on the way out. Add your own keys to
`_sensitiveKeyPattern` in that file when your API introduces them.

**Packages:** [`permission_handler`](https://pub.dev/packages/permission_handler), [`logger`](https://pub.dev/packages/logger)

---

## M7 — Insufficient Binary Protections

The compiled binary should be hardened against reverse engineering.

- [x] R8 keep rules configured for Android — `android/app/proguard-rules.pro`,
      written by `init` and reproduced below
- [x] The Android CI build obfuscates the Dart code — `build_apk.yml` passes
      `--obfuscate --split-debug-info=build/debug-info/android`
- [ ] R8 itself turned on. Writing the rules is not enabling them: without the
      gradle block below, the Java/Kotlin side is neither shrunk nor renamed
- [ ] Symbols kept. `build/debug-info/` is **not** uploaded by the generated
      workflow, so today it dies with the runner — see below
- [ ] The iOS CI build obfuscates too. `build_ipa.yml` compiles with
      `flutter build ios --release --no-codesign` and archives through
      `xcodebuild`, which does not carry the Dart obfuscation flags — see below
- [ ] App integrity / tamper detection, for high-risk apps

### Obfuscation

**Local release builds:**
```bash
# Android
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android

# iOS
flutter build ipa --release \
  --obfuscate \
  --split-debug-info=build/debug-info/ios
```

> ⚠️ Store the `build/debug-info/` folder, one copy per released build. Without
> the symbols for *that exact build*, its crash stack traces stay unreadable in
> Crashlytics and in both store consoles — and you cannot regenerate them
> afterwards.

**Keeping the symbols in CI** — add to `build_apk.yml`, next to the APK upload:

```yaml
- name: Upload debug symbols
  uses: actions/upload-artifact@v4
  with:
      name: debug-info-android
      path: build/debug-info/
      retention-days: 90
```

> 90 days is an artifact retention limit, not a crash-report lifetime. For
> anything you actually shipped, move the folder somewhere permanent, or upload
> it to Crashlytics.

**Obfuscating the iOS build.** The `xcodebuild archive` step re-invokes the
Flutter tool through the Xcode build phase, so the flags on `flutter build ios`
do not reach it. Pass them to the archive instead:

```yaml
xcodebuild -workspace Runner.xcworkspace \
  ... \
  EXTRA_GEN_SNAPSHOT_OPTIONS="--obfuscate" \
  EXTRA_FRONT_END_OPTIONS="--obfuscate" \
  archive
```

Verify it worked before trusting it — build once with and once without, and
check that `flutter symbolize` is needed to read a stack trace from the
obfuscated one.

**`android/app/build.gradle.kts` — enable R8:**
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true      // enables R8 (shrink + obfuscate)
        isShrinkResources = true    // removes unused resources
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro",
        )
        signingConfig = signingConfigs.getByName("release")
        isDebuggable = false
    }
}
```

> Turn this on early in a release cycle, not the night before. R8 breaks
> reflective lookups the rules below do not cover, and it only shows up in a
> release build.

---

### ProGuard Rules — `android/app/proguard-rules.pro`

`moarch init` already writes this file — it sits there doing nothing until the
R8 block above turns minification on.

```proguard
# ProGuard / R8 keep rules.
#
# These do nothing until R8 is turned on for the release build type
# (minifyEnabled / shrinkResources + proguardFiles) — see
# docs/SECURITY_BEFORE_DEPLOYMENT.md for that block and the rest of the
# pre-release checklist.

##──── Flutter engine ────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

##──── Dart / Flutter generated code ─────────────────────────────────────────
# Keep classes referenced via reflection or generated JSON serialisers
-keep class * extends io.flutter.plugin.common.PluginRegistry { *; }

##──── Google Play Core / In-App Updates & Integrity ────────────────────────
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

##──── Firebase ───────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

##──── OkHttp / Dio (networking) ─────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

##──── Kotlin coroutines ──────────────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory { *; }
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler { *; }
-dontwarn kotlinx.coroutines.**

##──── Serialisation — keep model classes from being stripped ────────────────
# If you use json_serializable or freezed, keep your data package:
# -keep class com.yourcompany.yourapp.data.models.** { *; }

##──── Prevent stripping enums ───────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

##──── Native methods ─────────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

##──── Debugging: preserve line numbers in stack traces ──────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
```

> Add rules incrementally — only suppress warnings (`-dontwarn`) for libraries you actually use. Run `./gradlew assembleRelease` and check the output for new warnings after each addition.

---

### App Integrity Verification

App integrity detects if your app has been tampered with, repackaged, or is running on an untrusted device. Use the **Play Integrity API** on Android and **DeviceCheck / App Attest** on iOS.

#### Android — Play Integrity API

```yaml
# pubspec.yaml — check pub.dev for the current package/version
# (e.g. play_integrity or play_integrity_flutter)
dependencies:
  play_integrity:
```

```dart
import 'package:play_integrity/play_integrity.dart';

Future<void> checkIntegrity() async {
  try {
    // 1. Get a nonce from YOUR backend (single-use, server-generated)
    final nonce = await myBackend.fetchIntegrityNonce();

    // 2. Request an integrity token from Google
    final token = await PlayIntegrity().requestIntegrityToken(nonce: nonce);

    // 3. Send the token to YOUR backend for verification
    //    Never verify the token on the client side
    final result = await myBackend.verifyIntegrityToken(token);

    if (!result.isValid) {
      // Block access, show error, or log for review
      throw AppException.integrityCheckFailed();
    }
  } on PlayIntegrityException catch (e) {
    // Handle errors: device not supported, Google Play not available, etc.
    logger.e('Integrity check error: ${e.message}');
  }
}
```

**What the backend verdict contains:**
```json
{
  "requestDetails": { "nonce": "...", "packageName": "com.example.app" },
  "appIntegrity": {
    "appRecognitionVerdict": "PLAY_RECOGNIZED", // or UNRECOGNIZED_VERSION / UNEVALUATED
    "certificateSha256Digest": ["..."]
  },
  "deviceIntegrity": {
    "deviceRecognitionVerdict": ["MEETS_DEVICE_INTEGRITY"] // or MEETS_STRONG_INTEGRITY
  },
  "accountDetails": {
    "appLicensingVerdict": "LICENSED" // verifies user purchased the app
  }
}
```

> ⚠️ Always verify the token server-side using the [Play Integrity API](https://developer.android.com/google/play/integrity/verdict). A client-side check can be bypassed.

**Packages:** [`play_integrity`](https://pub.dev/packages/play_integrity)

---

#### iOS — App Attest (DeviceCheck)

Apple's **App Attest** verifies the app binary and device before sensitive operations. It requires iOS 14+.

```dart
// Use a method channel or the app_attest package
// There is no first-party Flutter package — use a native Swift method channel

// ios/Runner/AppAttestService.swift
import DeviceCheck

func attestKey(challenge: Data) async throws -> Data {
    let service = DCAppAttestService.shared
    guard service.isSupported else { throw AttestError.notSupported }

    // 1. Generate a key (store the keyId for future assertions)
    let keyId = try await service.generateKey()

    // 2. Attest the key using a server-provided challenge hash
    let clientDataHash = Data(SHA256.hash(data: challenge))
    let attestationObject = try await service.attestKey(keyId, clientDataHash: clientDataHash)

    // 3. Send attestationObject + keyId to your backend for verification
    return attestationObject
}
```

**Flow summary:**
1. Backend generates a one-time challenge
2. App calls `DCAppAttestService.attestKey()` with a hash of the challenge
3. Apple's servers return a signed attestation object
4. Your backend verifies the attestation with Apple and stores the `keyId`
5. On subsequent requests, use `generateAssertion()` with the stored `keyId`

> ℹ️ App Attest has a rate limit in development — use the `DCAppAttestService.shared.isSupported` check and degrade gracefully on simulators.

**References:** [Apple App Attest docs](https://developer.apple.com/documentation/devicecheck/establishing_your_app_s_integrity), [Human-readable guide](https://nshipster.com/app-attest/)

---

## M8 — Security Misconfiguration

Build configuration and platform settings must be reviewed before release.

- [x] Debug-only behaviour is guarded by build mode, not by a flag someone can
      forget to flip — the logger's level and the Dio certificate override are
      both behind `kReleaseMode` / `kDebugMode`
- [x] Users never see a stack trace — every failure surfaces as an
      `AppException` with a message, rendered by `AppAsyncView` (Riverpod) or
      `AppStatusView` (bloc)
- [ ] `isDebuggable = false` in the Android release build type
- [ ] The `AppException` messages reviewed. They are generic by design, but the
      ones you add per feature are where internal detail leaks back in
- [ ] Feature flags / Remote Config used for presentation only — a flag the
      client evaluates is a flag the client can flip
- [ ] `minSdk` and the iOS deployment target above the EOL versions
- [ ] Store builds produced by `flutter build`, never a debug binary

**Example — guard debug-only code:**
```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  // only runs in debug builds
  print('Debug info: $sensitiveData');
}
```

> The generated `app_logger.dart` is the better habit: it is already
> mode-aware, and it redacts credentials at the sink so no call site has to
> remember to.

---

## M9 — Insecure Data Storage

Sensitive data at rest must be protected appropriately.

- [x] Tokens live in the platform keychain/keystore, not `SharedPreferences` —
      `core/security/secure_storage.dart` wraps `flutter_secure_storage`
- [x] One owner for the session, so there is one place that clears it —
      `TokenStorage`, used by both the Dio client and the auth repository
- [ ] Nothing sensitive written to plain files, logs or the app cache by code
      you added
- [ ] Database contents encrypted if they hold personal or financial data —
      nothing in the scaffold encrypts a local DB
- [ ] Clipboard cleared after copying sensitive data, or copying disabled
- [ ] Screenshots disabled on sensitive screens (not generated — snippet below)

**Example — the generated session store:**
```dart
// core/security/secure_storage.dart
final storage = getIt<TokenStorage>();

await storage.saveSession(accessToken: access, refreshToken: refresh);
final token = await storage.accessToken;
await storage.clearSession(); // on logout
```

**Example — disable screenshots on Android.** `init` does not add this; it
blocks the whole activity, including screens where a screenshot is legitimate,
so scope it to the routes that need it rather than setting it once at startup:

```kotlin
// MainActivity.kt — note moarch may already have made this a
// FlutterFragmentActivity for local_auth; keep whichever base class is there.
window.setFlags(
  WindowManager.LayoutParams.FLAG_SECURE,
  WindowManager.LayoutParams.FLAG_SECURE
)
```

> iOS has no equivalent flag. The usual approach is covering the window in
> `applicationWillResignActive` so the app-switcher snapshot shows a blank view.

**Packages:** [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage), [`sqflite_sqlcipher`](https://pub.dev/packages/sqflite_sqlcipher) (encrypted DB)

---

## M10 — Insufficient Cryptography

Cryptographic implementations must follow current best practices.

Nothing in the scaffold does its own cryptography — it stores tokens through
the platform keystore and talks TLS through the platform stack. Every item here
applies to code you add.

- [ ] No custom/homebrew cryptographic algorithms
- [ ] Weak algorithms (MD5, SHA-1, DES) are not used for sensitive operations
- [ ] Encryption keys are not hardcoded in the source, and not in `.env` either
      — `envied` obfuscates a value, it does not protect a key
- [ ] IVs (Initialization Vectors) are random and unique per encryption operation
- [ ] TLS version is 1.2 or higher (1.3 preferred)

**Example — AES-GCM encryption:**
```dart
// encrypt: ^5.x
import 'package:encrypt/encrypt.dart';

final key = Key.fromSecureRandom(32); // 256-bit key — store in secure storage
final iv = IV.fromSecureRandom(16);   // random IV per operation

final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
final encrypted = encrypter.encrypt(plainText, iv: iv);
final decrypted = encrypter.decrypt(encrypted, iv: iv);
```

**Packages:** [`encrypt`](https://pub.dev/packages/encrypt), [`pointycastle`](https://pub.dev/packages/pointycastle)

---

## Pre-Release Final Checks

- [x] `flutter analyze` and `flutter test` run on every push, if you took the
      workflows — the unit and integration suites are separate jobs
- [x] The CI pipeline reads credentials from GitHub secrets, never from the
      repository — `.env` is recreated per job and never committed
- [ ] Release build verified on a **physical** device, not only an emulator —
      obfuscation, R8 and signing all behave differently there
- [ ] The permissions in the final binary reviewed, not the ones you meant to
      request — check the merged manifest and the built `Info.plist`
- [ ] A crash from the release build symbolicated end to end, proving the
      archived symbols match what you shipped
- [ ] Privacy policy URL live and linked in both store listings
- [ ] GDPR / LGPD obligations met if you handle EU or BR user data
- [ ] `moarch doctor` clean, and `.moarch.yaml` committed

---

## References

- [OWASP Mobile Top 10 2024](https://owasp.org/www-project-mobile-top-10/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Android Security Checklist](https://developer.android.com/topic/security/best-practices)
- [Apple App Store Review Guidelines — Privacy](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)

