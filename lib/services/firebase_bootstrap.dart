import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'auth_service.dart';
import 'firebase_auth_service.dart';

Future<AuthService> initializeAuthentication() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FirebaseAuthService(FirebaseAuth.instance);
  } catch (_) {
    // Unsupported platforms and initialization errors fail closed. No raw logs.
    return const UnconfiguredAuthService();
  }
}
