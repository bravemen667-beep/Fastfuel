// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Firebase Options
//  Auto-selects the correct FirebaseOptions per platform.
//
//  Android  → sourced from android/app/google-services.json
//  iOS      → sourced from ios/Runner/GoogleService-Info.plist  ✅ REAL VALUES
//  macOS    → same iOS config (shared project)
//  Web      → add Web app in Firebase Console to fill appId
//
//  Usage in main.dart:
//    await Firebase.initializeApp(
//      options: DefaultFirebaseOptions.currentPlatform,
//    );
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// Returns the correct [FirebaseOptions] for the current platform.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android ──────────────────────────────────────────────────────────────
  // Source: android/app/google-services.json
  // Package: com.gofasterhealth.tracker
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWykgqQEIc9EEcIQ_9mC_LK7RA_m7gVYU',
    appId: '1:242417786200:android:42228916d5e66123c2192d',
    messagingSenderId: '242417786200',
    projectId: 'gofaster-ca39c',
    storageBucket: 'gofaster-ca39c.firebasestorage.app',
  );

  // ── iOS ──────────────────────────────────────────────────────────────────
  // Source: ios/Runner/GoogleService-Info.plist  ✅ Real values
  // Bundle ID: com.gofasterhealth.tracker
  // GOOGLE_APP_ID: 1:242417786200:ios:dc10f1f4b7b75073c2192d
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBNtUPSjiSxEBmg86CxJt1n194GJ93v9ts',
    appId: '1:242417786200:ios:dc10f1f4b7b75073c2192d',
    messagingSenderId: '242417786200',
    projectId: 'gofaster-ca39c',
    storageBucket: 'gofaster-ca39c.firebasestorage.app',
    iosBundleId: 'com.gofasterhealth.tracker',
  );

  // ── macOS ─────────────────────────────────────────────────────────────────
  // Uses same iOS plist config (shared Firebase project)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBNtUPSjiSxEBmg86CxJt1n194GJ93v9ts',
    appId: '1:242417786200:ios:dc10f1f4b7b75073c2192d',
    messagingSenderId: '242417786200',
    projectId: 'gofaster-ca39c',
    storageBucket: 'gofaster-ca39c.firebasestorage.app',
    iosBundleId: 'com.gofasterhealth.tracker',
  );

  // ── Web ───────────────────────────────────────────────────────────────────
  // ⚠️  appId needs a Web app registered in Firebase Console
  // Steps:
  //   1. Firebase Console → gofaster-ca39c → Project Settings → Your apps
  //   2. Click "Add app" → Web
  //   3. Copy the appId (looks like 1:242417786200:web:XXXXXXXXXX) and paste below
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAWykgqQEIc9EEcIQ_9mC_LK7RA_m7gVYU',
    appId: '1:242417786200:web:REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: '242417786200',
    projectId: 'gofaster-ca39c',
    storageBucket: 'gofaster-ca39c.firebasestorage.app',
    authDomain: 'gofaster-ca39c.firebaseapp.com',
  );
}
