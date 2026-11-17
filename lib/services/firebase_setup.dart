import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Debug builds use registered debug tokens; release builds never do.
Future<void> initializeFirebaseAI() async {
  if (!kIsWeb &&
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.macOS) {
    throw StateError('This app supports Android, iOS, macOS and web.');
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb ? WebDebugProvider() : null,
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider(),
    );
  } else {
    const siteKey = String.fromEnvironment('RECAPTCHA_ENTERPRISE_SITE_KEY');
    if (kIsWeb && siteKey.isEmpty) {
      throw StateError(
        'Set RECAPTCHA_ENTERPRISE_SITE_KEY when building for web. See docs/firebase-ai-logic.md.',
      );
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb ? ReCaptchaEnterpriseProvider(siteKey) : null,
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }
  // Token acquisition occurs on the first AI request, so an unregistered debug
  // token does not prevent opening the UI. Never log tokens ourselves.
}
