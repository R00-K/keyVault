import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for $defaultTargetPlatform - '
          'you can reconfigure by running "flutterfire configure".',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtEx02tYJGY48AqJpLcaaTHWfY1DgBgT8',
    appId: '1:714342543956:web:PLACEHOLDER_REGISTER_WEB_APP_IN_FIREBASE_CONSOLE',
    messagingSenderId: '714342543956',
    projectId: 'keyvault-e703b',
    authDomain: 'keyvault-e703b.firebaseapp.com',
    storageBucket: 'keyvault-e703b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtEx02tYJGY48AqJpLcaaTHWfY1DgBgT8',
    appId: '1:714342543956:android:1c49480cdd3be4df4373c1',
    messagingSenderId: '714342543956',
    projectId: 'keyvault-e703b',
    storageBucket: 'keyvault-e703b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBtEx02tYJGY48AqJpLcaaTHWfY1DgBgT8',
    appId: '1:714342543956:ios:PLACEHOLDER_ADD_IOS_APP_IN_FIREBASE_CONSOLE',
    messagingSenderId: '714342543956',
    projectId: 'keyvault-e703b',
    storageBucket: 'keyvault-e703b.firebasestorage.app',
    iosBundleId: 'com.example.keyvault',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBtEx02tYJGY48AqJpLcaaTHWfY1DgBgT8',
    appId: '1:714342543956:ios:PLACEHOLDER_ADD_IOS_APP_IN_FIREBASE_CONSOLE',
    messagingSenderId: '714342543956',
    projectId: 'keyvault-e703b',
    storageBucket: 'keyvault-e703b.firebasestorage.app',
    iosBundleId: 'com.example.keyvault',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBtEx02tYJGY48AqJpLcaaTHWfY1DgBgT8',
    appId: '1:714342543956:web:PLACEHOLDER_REGISTER_WEB_APP_IN_FIREBASE_CONSOLE',
    messagingSenderId: '714342543956',
    projectId: 'keyvault-e703b',
    authDomain: 'keyvault-e703b.firebaseapp.com',
    storageBucket: 'keyvault-e703b.firebasestorage.app',
  );
}
