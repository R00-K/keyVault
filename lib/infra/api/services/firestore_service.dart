import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static var _initialized = false;

  static FirebaseFirestore get instance => _firestore;

  static void initialize({
    bool persistenceEnabled = true,
    int? cacheSizeBytes,
  }) {
    if (_initialized) return;

    _firestore.settings = Settings(
      persistenceEnabled: persistenceEnabled,
      cacheSizeBytes: cacheSizeBytes,
    );
    _initialized = true;
  }

  static CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  static DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }
}
