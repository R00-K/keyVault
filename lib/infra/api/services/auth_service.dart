import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> register({
    required String email,
    required String password,
    String name = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      await credential.user?.updateDisplayName(trimmedName);
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static String errorMessage(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Something went wrong. Please try again.';
    }

    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' => 'No account exists for this email.',
      'wrong-password' => 'The password is incorrect.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Use a stronger password.',
      'network-request-failed' => 'Check your internet connection.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      _ => error.message ?? 'Authentication failed. Please try again.',
    };
  }
}
