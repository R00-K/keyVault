import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keyvault/infra/api/services/firestore_service.dart';
import 'package:keyvault/infra/api/models/user_model.dart';

class UserService {
  UserService._();

  static const String _collection = 'users';

  /// Create a new user document
  static Future<void> createUser(UserModel user) async {
    await FirestoreService.collection(
      _collection,
    ).doc(user.uid).set(user.toMap());
  }

  /// Get a user by UID
  static Future<UserModel?> getUser(String uid) async {
    final snapshot = await FirestoreService.collection(
      _collection,
    ).doc(uid).get();

    if (!snapshot.exists) return null;

    return UserModel.fromMap(snapshot.data()!);
  }

  /// Check if a user exists
  static Future<bool> userExists(String uid) async {
    final snapshot = await FirestoreService.collection(
      _collection,
    ).doc(uid).get();

    return snapshot.exists;
  }

  /// Update an existing user
  static Future<void> updateUser(UserModel user) async {
    await FirestoreService.collection(
      _collection,
    ).doc(user.uid).update(user.toMap());
  }

  /// Update only the online status
  static Future<void> updateOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    await FirestoreService.collection(
      _collection,
    ).doc(uid).update({'isOnline': isOnline, 'lastSeen': Timestamp.now()});
  }
}
