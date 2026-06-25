import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'infra/api/services/firestore_service.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirestoreService.initialize();

  runApp(const KeyVaultApp());
}
