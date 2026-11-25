import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static bool get isConfigured =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError(
        'DefaultFirebaseOptions is only configured for Android.',
      );
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAGWnSY3ukODNY4fDnz-BLkHdupRzoCfxw',
    appId: '1:754430121551:android:6c75a4263fd54260a53c3a',
    messagingSenderId: '754430121551',
    projectId: 'mobile-5aac8',
    storageBucket: 'mobile-5aac8.firebasestorage.app',
  );
}
