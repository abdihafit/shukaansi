import 'package:firebase_core/firebase_core.dart';

/// Firebase web configuration for the admin dashboard (SHUKAANSI Admin web
/// app in kumee-development). Web client configuration is public by design;
/// access is controlled by Firebase Auth and the security rules.
const adminFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyBIkDXawbq_M8RRLTxlI1kbXH-nrir3bBE',
  appId: '1:1070920046573:web:91abce0d367f2640c279e4',
  messagingSenderId: '1070920046573',
  projectId: 'kumee-development',
  authDomain: 'kumee-development.firebaseapp.com',
  storageBucket: 'kumee-development.firebasestorage.app',
);
