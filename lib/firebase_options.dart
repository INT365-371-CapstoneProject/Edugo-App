// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD8D-XmSmw_Udm_6ZjekqrSktasMpm6aWw',
    appId: '1:321601678890:web:80fb4c253f56647b199d53',
    messagingSenderId: '321601678890',
    projectId: 'edugo-833d8',
    authDomain: 'edugo-833d8.firebaseapp.com',
    storageBucket: 'edugo-833d8.firebasestorage.app',
    measurementId: 'G-D55MJXPXS6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDokWNhTBfXv1dlUo4wwH9HaIWchkLNpVc',
    appId: '1:321601678890:android:c2ccd492ac511fcd199d53',
    messagingSenderId: '321601678890',
    projectId: 'edugo-833d8',
    storageBucket: 'edugo-833d8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAZu8xZBAyzKzj-uHOuJmq_aq1eoMEvaD4',
    appId: '1:321601678890:ios:ecec4eec05ca9416199d53',
    messagingSenderId: '321601678890',
    projectId: 'edugo-833d8',
    storageBucket: 'edugo-833d8.firebasestorage.app',
    iosBundleId: 'com.example.edugo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAZu8xZBAyzKzj-uHOuJmq_aq1eoMEvaD4',
    appId: '1:321601678890:ios:ecec4eec05ca9416199d53',
    messagingSenderId: '321601678890',
    projectId: 'edugo-833d8',
    storageBucket: 'edugo-833d8.firebasestorage.app',
    iosBundleId: 'com.example.edugo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD8D-XmSmw_Udm_6ZjekqrSktasMpm6aWw',
    appId: '1:321601678890:web:c9b49ba96e8bf48a199d53',
    messagingSenderId: '321601678890',
    projectId: 'edugo-833d8',
    authDomain: 'edugo-833d8.firebaseapp.com',
    storageBucket: 'edugo-833d8.firebasestorage.app',
    measurementId: 'G-EVWKBLJT2H',
  );
}
