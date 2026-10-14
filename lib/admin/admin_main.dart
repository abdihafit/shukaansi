import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/photo_files.dart';
import 'admin_app.dart';
import 'admin_firebase_options.dart';
import 'firestore_admin_service.dart';

/// Entry point for the staff dashboard (web):
/// flutter build web -t lib/admin/admin_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: adminFirebaseOptions);
  final store = FirebaseFirestore.instance;
  runApp(
    AdminApp(
      service: FirestoreAdminService(
        store,
        FirebaseAuth.instance,
        // Same free-plan image store as the member app (DEC-014).
        FirestorePhotoFiles(store),
      ),
    ),
  );
}
