import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChr_SI16NYuflHJ6b-mT6J4W1lJzhuWxk',
    appId: '1:837702224477:web:d78160b7bf48d7064b9bb4',
    messagingSenderId: '837702224477',
    projectId: 'family-calendar-4850c',
    authDomain: 'family-calendar-4850c.web.app',
    storageBucket: 'family-calendar-4850c.firebasestorage.app',
    measurementId: 'G-TJPN6LMJXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJRY2hssA5O627pTdy9Bquq2FTknfGPDk',
    appId: '1:837702224477:android:a8b10cc29438dbb44b9bb4',
    messagingSenderId: '837702224477',
    projectId: 'family-calendar-4850c',
    storageBucket: 'family-calendar-4850c.firebasestorage.app',
  );
}
