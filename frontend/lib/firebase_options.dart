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
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "demo",
    appId: "demo",
    messagingSenderId: "demo",
    projectId: "demo-cowbnb",
    authDomain: "demo-cowbnb.firebaseapp.com",
    storageBucket: "demo-cowbnb.appspot.com",
    measurementId: "demo",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "demo",
    appId: "demo",
    messagingSenderId: "demo",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "demo",
    appId: "demo",
    messagingSenderId: "demo",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
    iosBundleId: "com.example.cowbnb",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "demo",
    appId: "demo",
    messagingSenderId: "demo",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
    iosBundleId: "com.example.cowbnb",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "demo",
    appId: "demo",
    messagingSenderId: "demo",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: "demo",
    appId: "demo",
    messagingSenderId: "demo",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
  );
}
