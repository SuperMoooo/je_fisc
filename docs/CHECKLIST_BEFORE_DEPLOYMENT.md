# Production Checklist

What still needs doing before a release.

Anything already ticked is what `moarch init` put in place — it is listed
rather than dropped so you can see it was considered, not so you can do it
again. Everything unticked is yours. Items that depend on an option you may not
have selected say so.

---

## Flavors

`moarch create flavors` sets `dev` / `staging` / `prod` up for both platforms
through **flutter_flavorizr**, and keeps one `main.dart` — yours, untouched. It
runs the native-side processors only, generates `lib/flavors.dart`, and gives
non-production flavors suffixed ids so the builds install side by side. The
flavored entries `init` wrote into `.vscode/launch.json` start working as soon
as it has run.

- [ ] Flavors set up, if this project needs them (`moarch create flavors`)
- [ ] With Firebase: each suffixed application id registered in the console,
      then `flutterfire configure` re-run

- https://pub.dev/packages/flutter_flavorizr

---

## Over-the-Air Updates (Code Push)

**shorebird_code_push** — allows pushing Dart code changes directly to users without going through the stores. Ideal for bug fixes and small updates. Requires a Shorebird account and `shorebird init` in the project.

- https://pub.dev/packages/shorebird_code_push
- https://shorebird.dev

---

## Store Version Check

**upgrader** — compares the installed app version against the current version on the App Store / Play Store and prompts the user to update when a new version is available.

- https://pub.dev/packages/upgrader

---

## Android

- [x] `android/app/proguard-rules.pro` written, covering the Flutter engine,
      Firebase, OkHttp and coroutines
- [x] `android/key.properties`, `*.jks` and `*.keystore` are in `.gitignore` —
      the keystore cannot be committed by accident
- [ ] R8 actually turned on for the release build type — the rules above do
      nothing until it is. The gradle block is in
      `SECURITY_BEFORE_DEPLOYMENT.md`
- [ ] Correct `applicationId` in `android/app/build.gradle.kts`
- [ ] Correct `versionName` / `versionCode` (or a `version:` in `pubspec.yaml`
      that produces them)
- [ ] `targetSdk` meets the current Play requirement
- [ ] Release keystore created, and stored where you will not lose it — losing
      it means never updating the app on Play again. `GENERATE_JKS_FILE.md`
- [ ] Signing config reading `key.properties` — `GENERATE_JKS_FILE.md`
- [ ] `android:debuggable` not set in the manifest
- [ ] Built as an **app bundle** for Play (`flutter build appbundle`) — the
      generated `build_apk.yml` produces an APK, which is for testing and
      direct distribution, not for the store
- [ ] Tested on a physical device

## iOS

- [x] Usage descriptions in `Info.plist` for the options you selected — camera,
      photo library, microphone, Face ID, the push background mode
- [x] `Runner.entitlements` / `RunnerProfile.entitlements`, if you selected
      Firebase push
- [ ] Usage descriptions for any permission you added yourself (location,
      contacts, …) — `init` only writes the ones for its own options
- [ ] Correct Bundle ID in Xcode, and `PRODUCT_BUNDLE_IDENTIFIER` right per
      scheme
- [ ] Signing certificate and provisioning profile configured
- [ ] Icons and launch screen generated — the generated
      `flutter_native_splash.yaml` is the config, `dart run
      flutter_native_splash:create` is the step
- [ ] Push: capability on the App ID, APNs key uploaded to Firebase, and the
      provisioning profile regenerated **after** enabling the capability
- [ ] Tested on a physical device

## General

- [x] `debugShowCheckedModeBanner: false` in the generated app
- [x] Failures reach the UI as an `AppException` through the view's shell
      (`AppAsyncView` on Riverpod, `AppStatusView` on bloc) — no raw exception
      or stack trace is shown to a user
- [x] `flutter analyze` and `flutter test` gate every push, if you took the
      workflows
- [ ] The wording of those error messages reviewed — the generated defaults are
      deliberately generic
- [ ] `.env` filled in for production (`BASE_URL`, …), and the matching GitHub
      secrets set for CI
- [ ] `dart run build_runner build --delete-conflicting-outputs` run wherever
      you build — `config/env/app_env.g.dart` is gitignored by design, so it
      does not travel with a clone
- [ ] All `TODO` comments resolved — the REST datasources ship with them where
      your endpoints go
- [ ] Unused dependencies removed from `pubspec.yaml`
- [ ] App version and build number bumped
- [ ] `flutter build` runs without warnings
- [ ] Tested on both Android and iOS
- [ ] Crash reporting configured — the Crashlytics option wires it into the
      error handlers and the logger; without it nothing reports
- [ ] `.moarch.yaml` committed, so `moarch update` can still tell your edits
      from untouched generated files
- [ ] If you took the maintenance gate: the flag exists on the backend and
      reads `false`, and you have tried it once against a real build. A gate
      nobody has tested is one you will not trust on the day you need it
