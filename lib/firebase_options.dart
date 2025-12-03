import 'package:firebase_core/firebase_core.dart';
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBmjFHn9PJldqMSEyqCWlEnjEJKbC4Ldfk',
    appId: '1:727056405171:android:c18ead8233562aebc2d6c6',
    messagingSenderId: '727056405171',
    projectId: 'event-booking42',
    storageBucket: 'event-booking42.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBZ63sXJZxwhx0s2aOsLfHIZ2Ua5669TU0',
    appId: '1:727056405171:ios:de2c8d09b5f4118bc2d6c6',
    messagingSenderId: '727056405171',
    projectId: 'event-booking42',
    storageBucket: 'event-booking42.firebasestorage.app',
    androidClientId: '727056405171-tcg0obiopv9a3nr8h3e71qc8r99p41qe.apps.googleusercontent.com',
    iosClientId: '727056405171-o2h6o636cn55tiknfr6i6e5k0ik56af1.apps.googleusercontent.com',
    iosBundleId: 'com.josim.eventbooking.eventBooking',
  );

}