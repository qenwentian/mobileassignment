import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const String _envApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _envAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _envSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _envProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _envStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static const String _apiKey = 'AIzaSyAGWnSY3ukODNY4fDnz-BLkHdupRzoCfxw';
  static const String _androidAppId =
      '1:754430121551:android:6c75a4263fd54260a53c3a';
  static const String _messagingSenderId = '754430121551';
  static const String _projectId = 'mobile-5aac8';
  static const String _storageBucket = 'mobile-5aac8.firebasestorage.app';

  static String _pick(String env, String fallback) =>
      env.isNotEmpty ? env : fallback;

  static bool get isConfigured {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final options = android;
    return [
      options.apiKey,
      options.appId,
      options.messagingSenderId,
      options.projectId,
    ].every((v) => v.isNotEmpty);
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'DefaultFirebaseOptions is only configured for Android.',
      );
    }
    return android;
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _pick(_envApiKey, _apiKey),
        appId: _pick(_envAppId, _androidAppId),
        messagingSenderId: _pick(_envSenderId, _messagingSenderId),
        projectId: _pick(_envProjectId, _projectId),
        storageBucket: _pick(_envStorageBucket, _storageBucket),
      );
}
