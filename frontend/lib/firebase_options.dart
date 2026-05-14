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
    apiKey: "AIzaSyAa8yy0GgGggg1g1g1g1g1g1g1g1g1g1g1",
    appId: "1:123456789012:web:abcdef1234567890",
    messagingSenderId: "123456789012",
    projectId: "demo-cowbnb",
    authDomain: "demo-cowbnb.firebaseapp.com",
    storageBucket: "demo-cowbnb.appspot.com",
    measurementId: "G-XXXXXXXXXX",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAa8yy0GgGggg1g1g1g1g1g1g1g1g1g1g1",
    appId: "1:123456789012:android:abcdef1234567890",
    messagingSenderId: "123456789012",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyAa8yy0GgGggg1g1g1g1g1g1g1g1g1g1g1",
    appId: "1:123456789012:ios:abcdef1234567890",
    messagingSenderId: "123456789012",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
    iosBundleId: "com.example.cowbnb",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyAa8yy0GgGggg1g1g1g1g1g1g1g1g1g1g1",
    appId: "1:123456789012:macos:abcdef1234567890",
    messagingSenderId: "123456789012",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
    iosBundleId: "com.example.cowbnb",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyAa8yy0GgGggg1g1g1g1g1g1g1g1g1g1g1",
    appId: "1:123456789012:windows:abcdef1234567890",
    messagingSenderId: "123456789012",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: "AIzaSyAa8yy0GgGggg1g1g1g1g1g1g1g1g1g1g1",
    appId: "1:123456789012:linux:abcdef1234567890",
    messagingSenderId: "123456789012",
    projectId: "demo-cowbnb",
    storageBucket: "demo-cowbnb.appspot.com",
  );
}
