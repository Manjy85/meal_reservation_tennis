import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// reCAPTCHA v3 site key for App Check on web, passed at build time:
/// `flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=...`
const _recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

/// Turns on Firebase App Check, which attaches a token proving requests come
/// from a genuine install of this app (Play Integrity on Android, App Attest
/// on iOS). Debug builds use the debug provider: the token it prints in the
/// logs must be registered in the Firebase console (App Check > Manage debug
/// tokens) once enforcement is on. See SECURITY.md.
Future<void> activateAppCheck() async {
  if (kIsWeb) {
    // No site key configured: skip rather than fail, web is only used for testing.
    if (_recaptchaSiteKey.isEmpty) return;
    await FirebaseAppCheck.instance.activate(providerWeb: ReCaptchaV3Provider(_recaptchaSiteKey));
    return;
  }
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
}
