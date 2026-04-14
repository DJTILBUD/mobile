// File generated based on google-services.json and GoogleService-Info.plist
// To regenerate: install flutterfire CLI and run `flutterfire configure`

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB45vMpGQzz0H5qmQfQIPVBLilEICVb8ik',
    appId: '1:931620942819:android:d0eadd85c421a38891a6d6',
    messagingSenderId: '931620942819',
    projectId: 'djtilbud-8cdba',
    storageBucket: 'djtilbud-8cdba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDustQaaUNHAGj59AdqLdADKryb-69snrY',
    appId: '1:931620942819:ios:236fe2c634b2340791a6d6',
    messagingSenderId: '931620942819',
    projectId: 'djtilbud-8cdba',
    storageBucket: 'djtilbud-8cdba.firebasestorage.app',
    iosBundleId: 'com.djtilbud.app',
  );
}
