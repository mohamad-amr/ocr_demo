# MathLens Firebase setup

For complete debug and production instructions for each platform, see [App Check: Android, iOS and web](app-check-platforms.md).

## What is implemented

The app always initializes Firebase and uses Gemini for corrections. There is no offline demo mode.

- `lib/services/firebase_setup.dart`: Firebase initialization and App Check. Debug builds use debug providers on Android, Apple and web. Profile/release builds use Play Integrity, App Attest with DeviceCheck fallback, or reCAPTCHA Enterprise.
- `lib/services/gemini_ocr_service.dart`: Gemini Developer API request with PDF bytes, 10 MB application limit, 20-second App Check verification timeout and 3-minute AI response timeout, structured JSON schema, truncation detection and actionable errors.
- `lib/models/math_correction.dart`: validates model JSON and verdicts.
- `lib/services/correction_pdf.dart`: renders the original worksheet pages, adds marks and margin notes, and appends detailed corrections with embedded local fonts.
- `lib/cubit/ocr_cubit.dart`: prevents duplicate submissions, ignores stale results after reset, validates input and exports `_correction.pdf`.
- Existing widgets show real-mode labels and explain that Google receives the uploaded PDF.

No Firebase Console settings were changed. A live Gemini call has not been verified. No Gemini API key is embedded in the app.

## First run: use Chrome

1. Open https://console.firebase.google.com/ and select **ocr-demo-90227**.
2. Open **Firebase AI Logic**, select **Get started** if shown, and choose **Gemini Developer API**. Finish enabling the required services. Review the console's quota/billing requirements for the selected model.
3. Open **Security > App Check > APIs**. Select Firebase AI Logic and enforce baseline protection. Leave replay protection disabled for this initial setup: this code does not request limited-use tokens.
4. Run:

   ```sh
   flutter run -d chrome
   ```

5. Open Chrome developer tools, then **Console**. Look for `AppCheck debug token`. If it has not appeared, choose a small PDF and click **Check solution** to trigger a token request. The first request can fail until you register the token.
6. Copy the debug token privately. In Firebase Console, open **App Check > Apps**, find the **web app**, open its overflow menu, and choose **Manage debug tokens**. Add a token named `Local Chrome` and paste it there.
7. Restart the app, select a PDF under 10 MB, and click **Check solution**. Try a single-page worksheet first.

Use the web app entry, not Android or Apple. Debug tokens are tied to the app registration. A different browser profile or device can need a new token. Do not put the token in source control or share it in screenshots.

The installed App Check SDK has `WebDebugProvider()`, which configures web debug mode automatically. **Do not add a debug script to `web/index.html`.** Earlier guide examples showing that script are unnecessary for this implementation.

Creating a debug token is not creating a Gemini API key. It lets Firebase accept requests from your development installation while enforcement stays enabled.

## Android emulator or device

Run `flutter devices`, then `flutter run -d DEVICE_ID`. The debug build uses `AndroidDebugProvider`. Find the App Check token in the terminal/logcat and register it under the **Android app** in App Check. Restart and retry.

The current Android application ID is `com.example.ocr_demo`; it must match the Firebase app. Release internet permission has been added. For publication, choose your permanent application ID before regenerating Firebase configuration.

## iOS simulator or macOS

Run `flutter run -d DEVICE_ID` or `flutter run -d macos`. Register the printed token under the corresponding Apple app in App Check; iOS and macOS are separate registrations.

If Apple logs do not show the token, open `ios/Runner.xcworkspace` or `macos/Runner.xcworkspace` in Xcode. Under **Product > Scheme > Edit Scheme > Run > Arguments**, add `-FIRDebugEnabled` for local debugging, run again, and inspect the Xcode console. Trigger one correction request if needed. Remove verbose debug logging before publishing.

The generated macOS release entitlements already allow outgoing network requests and user-selected files.

Firebase AI mode supports Android, iOS, macOS and web. Windows/Linux are not supported by the installed Firebase AI plugin.

## Production setup outside the codebase

Debug provider registration is for development only. This app automatically stops using debug providers in profile/release builds.

| Target | Firebase Console / platform action |
| --- | --- |
| Android | Register Play Integrity in App Check, configure the correct signing SHA-256 fingerprints and Play Console linkage/settings for your distribution. Fill in the ignored `android/key.properties` using the supplied example; release builds now use release signing. |
| iOS / macOS | Register App Attest and the DeviceCheck fallback in App Check. Configure the Apple team, bundle ID, signing/capabilities and credentials required by those providers. Verify support on real target devices. |
| Web | Create a reCAPTCHA Enterprise website key in the linked Google Cloud project, configure your deployed domains, and register that key for the Firebase web app in App Check. Pass its site key when building. |

Web production registration, step by step:

1. In Google Cloud Console, select `ocr-demo-90227` and open reCAPTCHA (it may appear under Fraud Defense).
2. Enable the reCAPTCHA Enterprise API if prompted.
3. Create a **Web** key. Add your deployed domain(s), for example your actual Firebase Hosting domain and custom domain.
4. Use a **score-based** key; leave **Use checkbox challenge** unchecked. Do not add localhost to the production key.
5. Copy the site key. Return to Firebase Console > App Check > Apps, select your web app, choose reCAPTCHA Enterprise, and register the key.
6. Build using the command below, deploy that build, and inspect App Check request metrics after a real request from the deployed domain.

Reference: https://firebase.google.com/docs/app-check/web/recaptcha-enterprise-provider

Web release command:

```sh
flutter build web --dart-define=RECAPTCHA_ENTERPRISE_SITE_KEY=YOUR_SITE_KEY
```

The site key is public configuration, not a secret key. Do not use an App Check debug token in its place. The app shows a setup error if this key is missing from a release web build.

Keep AI Logic App Check enforcement enabled. Review request quotas, billing budgets/alerts and usage before sharing publicly. Budget alerts do not impose a hard spending cap. No database or Storage setup is needed for the current inline-PDF flow.

## Configuration

```sh
# Change model without editing Dart:
flutter run -d chrome --dart-define=GEMINI_MODEL=gemini-3.5-flash-lite
```

The default model is `gemini-3.5-flash-lite`, a lighter model supporting PDF input and structured JSON. It is selected to try a different model after overload errors; current spare capacity and handwritten-math quality have not been verified. See [model capabilities](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite). Verify availability in the selected provider if you receive a model error. Stop and relaunch with the command above if an existing `GEMINI_MODEL` override selects another model. No Firebase/App Check registration change is required solely for this model switch. `flutterfire configure --project=ocr-demo-90227` is needed only when registering another target or changing app identities/project configuration.

## How correction works

The app reads the selected PDF and validates its size/header. Clicking Check solution uploads it through Firebase AI Logic to Gemini. App Check attaches attestation automatically. Gemini responds with summary and per-problem question, student work, verdict, explanation and corrected steps. JSON is validated before the app renders a PDF locally. Selecting a file alone does not send it to Gemini.

The 3-minute AI response timeout stops waiting in the client; it does not guarantee cancellation at the provider. Reset discards stale results but does not cancel an already-sent request. There are no automatic AI retries.

Initial output is English with plain-text math (`x^2`, `sqrt(x)`). The output preserves source pages visually and adds marks plus correction notes; it is not a searchable OCR overlay. Arabic/LaTeX rendering needs additional font/layout work. Gemini can misread handwriting or make mathematical errors; inspect the transcription. Schema constraints ensure structure, not correctness. Reports are capped at 30 problems per request and 100 generated pages; split larger worksheets.

## Troubleshooting

- **403 / App Check:** wrong app registration, unregistered debug token, or production attestation configuration. Register the token for the actual running platform, restart and retry. Also verify AI Logic is enabled.
- **404 / model unavailable:** confirm `GEMINI_MODEL` and Gemini Developer API availability.
- **429 / quota:** inspect quota and billing; avoid repeated retries.
- **Timeout:** retry a smaller worksheet after checking connectivity.
- **Incomplete response:** split into fewer pages; no partial JSON is shown as a completed report.
- **Startup setup screen:** verify generated Firebase options, supported platform, and the web release site key. Fix the configuration and restart/rebuild.

## References

- https://firebase.google.com/docs/ai-logic/get-started?platform=flutter
- https://firebase.google.com/docs/ai-logic/app-check
- https://pub.dev/documentation/firebase_app_check/latest/firebase_app_check/WebDebugProvider-class.html
- https://firebase.google.com/docs/ai-logic/analyze-documents
- https://firebase.google.com/docs/ai-logic/generate-structured-output

## CocoaPods installation on this Mac

The iOS Podfile uses `$FirebaseSDKVersion = '12.19.0'` to select the shared 12.19 patch range: the AppCheck pod index does not publish the 12.19.3 patch requested by firebase_core's default. Keep the resulting `ios/Podfile.lock` for reproducible resolution.

If the specs CDN reports an HTTP/2 framing error, use the opt-in HTTP/1.1 workaround in this project's Podfile:

```sh
cd ios
COCOAPODS_USE_HTTP1=1 COCOAPODS_CDN_MAX_CONCURRENCY=1 pod install --repo-update
cd ..
```

This workaround applies to that command only; it does not modify your global CocoaPods installation. App Check token registration cannot fix CocoaPods download or dependency-resolution errors.

### Requests that time out

App Check is verified before uploading the PDF, with a separate 20-second deadline. An App Check timeout or failure means this attempt did not send the PDF to Gemini. In local Chrome debug builds, register the debug token printed in the browser console under Firebase Console → App Check → web app → Manage debug tokens. The production reCAPTCHA site-key field is a different setup.

After verification, the app waits up to three minutes for the AI response. A timeout does not prove the server stopped processing. Check Firebase AI Logic monitoring and the browser Network panel for a failed request/status, then test with a one-page PDF. Do not repeatedly submit while diagnosing. Switching to iOS or Android will not resolve a web App Check registration problem; those platforms require their own registration. No console changes are required solely for the longer client timeout.

### Generic 400 INVALID_ARGUMENT

The server can return only "Request contains an invalid argument." This does not identify which field failed or prove an App Check issue. The response schema omits nested array length constraints to reduce schema complexity; the prompt and local parser still enforce 30 problems and 50 steps per problem. This is a mitigation, not proof of the cause of a particular 400.

If it persists, inspect the failed request in Chrome Network: confirm the endpoint ends in `:generateContent`, identify the model in the URL path, and inspect `generationConfig` in Payload. Share only the endpoint path (without query parameters) and `generationConfig`; omit headers, keys, tokens and the PDF's base64 data. An error from an App Check token exchange endpoint requires different troubleshooting.

## Marked worksheet and preview update (2026-11-16)

No additional Firebase Console or App Check changes are required for this UI/PDF update. Existing setup still applies.

The Gemini response now includes `marginNote` (a short comment) and `location`: a 1-based `page` and `box` array `[top, left, bottom, right]` using coordinates from 0 to 1000. Unknown locations use page 0 and are omitted from overlays. The parser rejects invalid boxes without losing the feedback. Locations are model estimates, not guaranteed exact positions.

The client rasterizes the uploaded PDF at 120 dpi with `printing`, preserving its visual handwriting rather than its editable PDF objects. It supports up to 20 source pages. Rendering errors stop generation instead of silently discarding original pages. The web renderer uses PDF.js, so its scripts and worker must be reachable under your deployment network/CSP settings.

The preview rasterizes the completed PDF at 96 dpi and places every page in one column. The whole page, including its header and footer, owns scrolling; the PDF has no nested scroll area. Large documents use more client memory. The download retains the generated PDF, not the preview images.


كنت عايز أجرب Firebase AI Logic مع Flutter في مشروع بسيط، ومن هنا جات فكرة **MathLens**.

الفكرة إن الطالب يرفع PDF فيه مسائل رياضة محلولة بخط الإيد، والـ AI يراجع الحلول ويرجّع نفس الورقة عليها علامات تصحيح وملاحظات، مع شرح للأخطاء.

استخدمت Firebase AI Logic مع Gemini، وببعت الـ PDF للموديل وبستقبل النتيجة في Structured JSON عشان أقدر أتعامل معاها جوه التطبيق.

أكتر جزء كان ممتع بالنسبة لي مش ربط الـ AI نفسه، لكن تحويل النتيجة لحاجة مفيدة للمستخدم.

في شوية تفاصيل ركزت عليها أثناء التجربة:

- PDF Annotation: الحفاظ على صفحات الطالب الأصلية وإضافة التصحيحات والملاحظات عليها، مع شرح تفصيلي في آخر الملف.

- Positioning: استخدام رقم الصفحة وإحداثيات الملاحظات من رد الموديل، مع Validation قبل رسمها عشان أتجنب وضع علامات بإحداثيات غير صالحة.

- Structured Output: التحقق من الـ JSON والتعامل مع الردود الناقصة بدل عرض نتيجة غير مكتملة.

- Firebase App Check: تجربة حماية طلبات الـ AI باستخدام Debug Provider أثناء التطوير، وتجهيز الـ providers المناسبة لكل منصة للـ production.

- File Handling: دعم Drag & Drop، والتحقق من نوع وحجم الملفات، وعرض الـ PDF بعد التصحيح.

واجهت كمان مشاكل زي بطء استجابة الموديل وأخطاء الضغط على الخدمة، فجرّبت موديل أخف وضفت Timeout وError Handling أوضح.

المشروع لسه Experiment / Proof of Concept، ومش الهدف منه إنه يكون نظام تصحيح يعتمد عليه بشكل كامل، خصوصًا إن قراءة خط الإيد وتقييم الحلول بالـ AI لسه ممكن يحصل فيهم أخطاء.

لكن التجربة كانت فرصة كويسة أفهم Firebase AI Logic بشكل عملي، وأتعامل مع Structured Outputs وPDF Annotation وApp Check في Flutter.

#Flutter #Firebase #FirebaseAILogic #Gemini #EdTech