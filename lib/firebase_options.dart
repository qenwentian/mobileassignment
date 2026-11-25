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
  static const String _envAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String _envStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static const String _apiKey = 'AIzaSyAGWnSY3ukODNY4fDnz-BLkHdupRzoCfxw';
  static const String _androidAppId = '1:754430121551:android:6c75a4263fd54260a53c3a';
  static const String _webAppId = 'YOUR_WEB_APP_ID';
  static const String _iosAppId = 'YOUR_IOS_APP_ID';
  static const String _messagingSenderId = '754430121551';
  static const String _projectId = 'mobile-5aac8';
  static const String _authDomain = 'mobile-5aac8.firebaseapp.com';
  static const String _storageBucket = 'mobile-5aac8.firebasestorage.app';

  static String _pick(String env, String fallback) =>
      env.isNotEmpty ? env : fallback;

  static FirebaseOptions _buildOptions({
    required String appId,
    String? authDomain,
    String? iosBundleId,
  }) {
    final projectId = _pick(_envProjectId, _projectId);
    final resolvedStorageBucket = _pick(_envStorageBucket, _storageBucket);
    String? resolvedAuthDomain;
    if (authDomain != null) {
      if (_envAuthDomain.isNotEmpty) {
        resolvedAuthDomain = _envAuthDomain;
      } else if (!authDomain.startsWith('YOUR_')) {
        resolvedAuthDomain = authDomain;
      } else if (!projectId.startsWith('YOUR_')) {
        resolvedAuthDomain = '$projectId.firebaseapp.com';
      } else {
        resolvedAuthDomain = authDomain;
      }
    }
    return FirebaseOptions(
      apiKey: _pick(_envApiKey, _apiKey),
      appId: _pick(_envAppId, appId),
      messagingSenderId: _pick(_envSenderId, _messagingSenderId),
      projectId: projectId,
      authDomain: resolvedAuthDomain,
      storageBucket: resolvedStorageBucket.startsWith('YOUR_')
          ? null
          : resolvedStorageBucket,
      iosBundleId: iosBundleId,
    );
  }

  static bool get isConfigured {
    try {
      final options = currentPlatform;
      return [
        options.apiKey,
        options.appId,
        options.messagingSenderId,
        options.projectId,
      ].every((v) => v.isNotEmpty && !v.startsWith('YOUR_'));
    } on UnsupportedError {
      return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web =>
      _buildOptions(appId: _webAppId, authDomain: _authDomain);

  static FirebaseOptions get android => _buildOptions(appId: _androidAppId);

  static FirebaseOptions get ios => _buildOptions(
        appId: _iosAppId,
        iosBundleId: 'com.example.mobileApp',
      );

  static FirebaseOptions get macos => _buildOptions(
        appId: _iosAppId,
        iosBundleId: 'com.example.mobileApp',
      );

  static FirebaseOptions get windows =>
      _buildOptions(appId: _webAppId, authDomain: _authDomain);
}
