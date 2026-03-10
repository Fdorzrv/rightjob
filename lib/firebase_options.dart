import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC60p3_ZPbxu4YgiolYouDnWkNo3xvFQZk',
    authDomain: 'rightjob-42041.firebaseapp.com',
    projectId: 'rightjob-42041',
    storageBucket: 'rightjob-42041.firebasestorage.app',
    messagingSenderId: '674552295374',
    appId: '1:674552295374:web:2e874139f30da55800c59f',
    measurementId: 'G-HC18X1L8DQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC60p3_ZPbxu4YgiolYouDnWkNo3xvFQZk',
    authDomain: 'rightjob-42041.firebaseapp.com',
    projectId: 'rightjob-42041',
    storageBucket: 'rightjob-42041.firebasestorage.app',
    messagingSenderId: '674552295374',
    appId: '1:674552295374:web:2e874139f30da55800c59f',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC60p3_ZPbxu4YgiolYouDnWkNo3xvFQZk',
    authDomain: 'rightjob-42041.firebaseapp.com',
    projectId: 'rightjob-42041',
    storageBucket: 'rightjob-42041.firebasestorage.app',
    messagingSenderId: '674552295374',
    appId: '1:674552295374:web:2e874139f30da55800c59f',
  );
}