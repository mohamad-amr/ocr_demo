# MathLens

Flutter app for correcting handwritten mathematics in uploaded PDFs with Gemini through Firebase AI Logic.

[App Check setup for Android, iOS and web — debug and production](docs/app-check-platforms.md)

## Run

```sh
flutter pub get
flutter run -d chrome
```

Real AI mode is the default. Complete [Firebase and App Check setup](docs/firebase-ai-logic.md) first. For local Chrome, register the App Check debug token printed in the browser console. No manual debug script is needed.

For production web, register reCAPTCHA Enterprise for your deployed domain, then:

```sh
flutter build web --dart-define=RECAPTCHA_ENTERPRISE_SITE_KEY=YOUR_SITE_KEY
```

Override the model with `--dart-define=GEMINI_MODEL=MODEL_NAME`. The default is `gemini-3.5-flash-lite`, a lighter model supporting PDF input and structured JSON. Spare capacity is not guaranteed; check correction quality on representative worksheets.

## Flow

Choose or drag in a PDF (up to 10 MB and 20 pages), then click **Mark my worksheet**. Google analyzes the work. The download preserves each original page as an image, adds numbered teacher-style marks and margin comments, and appends full corrections. Every page includes `made by dev.mohamed amr`.

The preview displays all pages at full width in the main page flow, without an internal PDF scroller. Missing or invalid AI locations are kept in the correction notes rather than placed on the worksheet. Marks and feedback still need human review.

Current output is English with plain-text math. Check the transcription and feedback; AI can make errors. The report is separate from the original PDF and does not annotate its pages.

## Checks

```sh
flutter analyze
flutter test
```

Tests use injected responses and do not call Gemini. Live verification needs Firebase Console configuration and a registered development token or production provider.

## PDF worker on web

PDF layout, image embedding/compression and export run in a dedicated browser
worker. Source-PDF rasterization and preview rendering still use the browser's
PDF renderer. This removes the PDF composer's CPU work from Flutter's UI thread;
it does not guarantee every frame is smooth or reduce the total CPU work.

The compiled `assets/workers/pdf_builder.js` is included as a Flutter asset, so
normal `flutter run` / `flutter build web` commands include it. After changing
`pdf_composer.dart`, `pdf_worker_protocol.dart`, the correction model, PDF package
versions or `tool/pdf_worker.dart`, rebuild it before running/deploying:

```sh
sh tool/build_pdf_worker.sh
```

Commit the regenerated JavaScript along with those source changes. Keep the
worker asset in the deployment; a restrictive Content Security Policy must allow
same-origin workers (`worker-src 'self'`). Worker errors/timeouts do not silently
fall back to building the PDF on the UI thread. No Firebase/App Check changes are
needed. Restart the current Flutter run after pulling this change.
