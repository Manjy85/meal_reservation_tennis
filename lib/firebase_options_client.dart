// Generated from the Firebase project "meal-reservation-tennis" for the client app.
// Firebase API keys are not secrets (they ship inside every app); access
// control is enforced by the Firestore security rules (firestore.rules).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class ClientFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Firebase is only configured for Android and web (use -d chrome or an Android device).',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWtIYj9Wz71fWgYroaJX9cW8E7Br0xIwA',
    appId: '1:825952577027:android:75091fbbab6af26b7b5036',
    messagingSenderId: '825952577027',
    projectId: 'meal-reservation-tennis',
    storageBucket: 'meal-reservation-tennis.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB9B-Ql1u3wKrjvs0OG99kEmcwK_dz3tsM',
    appId: '1:825952577027:web:f9191759e878bba27b5036',
    messagingSenderId: '825952577027',
    projectId: 'meal-reservation-tennis',
    authDomain: 'meal-reservation-tennis.firebaseapp.com',
    storageBucket: 'meal-reservation-tennis.firebasestorage.app',
  );
}
