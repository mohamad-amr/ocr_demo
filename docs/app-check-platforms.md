# App Check: Android, iOS and web

This project's provider selection is already implemented in `lib/services/firebase_setup.dart`. No tokens or private keys belong in Dart. The table describes this app's configuration, not Flutter defaults.

| Platform | Debug (`flutter run`) | Profile / release |
| --- | --- | --- |
| Android | `AndroidDebugProvider` | `AndroidPlayIntegrityProvider` |
| iOS | `AppleDebugProvider` | `AppleAppAttestWithDeviceCheckFallbackProvider` |
| Web | `WebDebugProvider` | `ReCaptchaEnterpriseProvider` with build-time site key |

Debug tokens are separate for each Firebase app registration and development installation. Your web token does not authorize Android or iOS. Profile builds use production attestation too. A simulator should use a debug build.

## 1. Shared Firebase setup

Open [Firebase Console](https://console.firebase.google.com/project/ocr-demo-90227/appcheck). Select project **ocr-demo-90227**, then **Security → App Check → Apps**. Each platform has its own entry. Current identifiers in this repository:

- Android package: `com.example.ocr_demo`.
- iOS bundle ID: `com.example.ocrDemo`.
- Web: the `ocr_demo (web)` Firebase registration.

Match these against Project settings → Your apps. If you choose permanent store identifiers, register those apps and rerun `flutterfire configure --project=ocr-demo-90227`; changing just the native identifier is insufficient. Keep Firebase AI Logic enabled. Under App Check → APIs, use its baseline enforcement with registered clients; this app does not use replay protection/limited-use tokens. Console registration has not been performed by this code change.

## 2. Android debug

1. Start an emulator or connect a device and run `flutter devices`.
2. Run `flutter run -d DEVICE_ID` (no `--release`).
3. Submit a small worksheet to trigger App Check. Find `DebugAppCheckProvider` / the debug secret in the run output or Android Studio Logcat.
4. In App Check → Apps, open the **Android app's** three-dot menu → **Manage debug tokens**. Add a descriptive name and that token.
5. Restart and retry. The first request before registration may fail.

You do not need a production signing certificate or a Play Store upload for this debug flow. A teammate runs the same code and registers their own token; do not distribute yours. Revoke unused tokens. These steps use Firebase's [Flutter debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider).

## 3. Android production

### Local signing configuration

Release builds now use the `release` signing configuration rather than silently signing with the debug key. Debug builds are unaffected.

1. Create your upload keystore if you do not already have one:

   ```sh
   keytool -genkeypair -v -keystore /absolute/path/to/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties`. Fill in its absolute keystore path, alias and passwords locally. The file and keystores are ignored by Git. Back up the keystore securely. Do not replace an existing published app's key arbitrarily.
3. Inspect your local certificate using `keytool -list -v -keystore /absolute/path/to/upload-keystore.jks -alias upload`. Record its SHA-256 fingerprint.

### External registration

1. In Play Console → your app → App integrity → Play Integrity API, link **ocr-demo-90227** as the Cloud project.
2. Register **Play Integrity** on the Firebase Android App Check entry with the certificate SHA-256 for the installed app. For Play App Signing, use the **app signing certificate** from Play Console; the upload certificate can differ. Direct APK installs use the certificate that signed that APK.
3. Match App Check's advanced policy to distribution: Play-only can require `PLAY_RECOGNIZED` and `LICENSED`; outside-Play-only should not require either and should require device integrity. A sideloaded release APK can fail a Play-only policy.
4. Build `flutter build appbundle --release`, distribute through a Play testing track, and verify App Check metrics with a real device. For direct distribution, use `flutter build apk --release` and the corresponding policy.

See Firebase's [Play Integrity setup and distribution settings](https://firebase.google.com/docs/app-check/android/play-integrity-provider). Missing local signing properties must be completed before a signed release can build.

## 4. iOS debug

1. Start an iOS simulator or connect an iPhone; run `flutter run -d DEVICE_ID`.
2. If the token is not visible, open `ios/Runner.xcworkspace` in Xcode. Under Product → Scheme → Edit Scheme → Run → Arguments, add `-FIRDebugEnabled` to Arguments Passed On Launch for local debugging.
3. Run, submit a worksheet, and find `App Check debug token` in the Xcode console.
4. Register it under **the iOS app** → Manage debug tokens, then restart and retry.

A web or Android token cannot substitute. Remove verbose logging when finished. The debug configuration deliberately has no App Attest entitlement requirement. Real-device debug still needs ordinary Apple signing. See [Firebase's iOS debug instructions](https://firebase.google.com/docs/app-check/flutter/debug-provider).

## 5. iOS production

1. In Xcode → Runner target → Signing & Capabilities, select your Apple Developer team and confirm the bundle ID. The repository currently selects team `6Q5TA24238`; use your own authorized team if different.
2. Enable **App Attest** for the app/capability and refresh provisioning profiles if needed. This project now sets `CODE_SIGN_ENTITLEMENTS = Runner/Release.entitlements` for **Release and Profile**. Its App Attest environment is **production**, as Firebase requires, including development-signed builds that use real attestation. Keep Debug without that entitlement requirement.
3. In Firebase App Check → iOS app, register **App Attest**, supplying the Apple team information requested by the console.
4. Also register **DeviceCheck**, because the configured provider falls back on devices where App Attest is unavailable. In Apple Developer → Certificates, Identifiers & Profiles → Keys, create a DeviceCheck key. Supply the `.p8` private key, key ID and team ID in Firebase's DeviceCheck registration. Never bundle that private key in the app.
5. Run a release build on a real iPhone or distribute with TestFlight (`flutter build ipa --release`). Check requests in App Check metrics. Simulator tests do not validate production attestation.

The entitlement file alone does not provision your Apple account. See [Firebase App Attest setup](https://firebase.google.com/docs/app-check/ios/app-attest-provider) and [DeviceCheck registration](https://firebase.google.com/docs/app-check/ios/devicecheck-provider).

## 6. Web debug

1. Run `flutter run -d chrome`.
2. Submit a worksheet; look in the browser Console for the App Check debug token.
3. Under **the web app** → Manage debug tokens, register it and restart/retry.

The installed SDK's `WebDebugProvider()` handles debug activation. No script or debug token needs to be added to `web/index.html`. Different browser profiles/storage may need separate registration. No production site key is required in debug mode.

## 7. Web production

1. In Google Cloud, select **ocr-demo-90227** → Fraud Defense / reCAPTCHA. Enable its API if prompted.
2. Create a **Web, score-based** key. Add your actual deployed domains, not `localhost`; leave checkbox challenges disabled.
3. Register that site key under Firebase App Check → **web app** → reCAPTCHA Enterprise.
4. Build and deploy:

   ```sh
   flutter build web --release --dart-define=RECAPTCHA_ENTERPRISE_SITE_KEY=YOUR_SITE_KEY
   ```

5. Submit a worksheet on the deployed domain and inspect App Check metrics. Rebuild if you change the key. A site key is public; it is not your debug token or a secret API key.

See [Firebase's web production instructions](https://firebase.google.com/docs/app-check/web/recaptcha-enterprise-provider).

## Verify and troubleshoot

The app requests an App Check token before uploading the worksheet. If that fails, verify the platform registration and build mode first. Android: check the actual signing SHA-256 and distribution policy. iOS: check team, provisioning, entitlement and both providers. Web: check site key and domain. A valid App Check token does not fix model overload, quota errors, or invalid Gemini request arguments.

No production attestation or store signing was verified by these edits. Complete account registration with your credentials, then test each platform before publication.
