// File ini di-generate dari google-services.json milik project apbtugas-f6737
// Jika ingin di-regenerate: dart pub global activate flutterfire_cli && flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
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

  // Nilai diambil dari: android/app/google-services.json
  // Project: apbtugas-f6737
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC2TNf2mMs0g-Msdhl7U3Qez--09-2rrZs',
    appId: '1:11024842594:android:82c3c47d8bedc95343763b',
    messagingSenderId: '11024842594',
    projectId: 'apbtugas-f6737',
    storageBucket: 'apbtugas-f6737.firebasestorage.app',
  );
}
