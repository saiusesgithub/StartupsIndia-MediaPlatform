import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Abstract contract for authentication operations.
/// The UI layer depends on this, not on [FirebaseAuthRepositoryImpl].
abstract class AuthRepository {
  /// Returns the currently signed-in [User], or null if not authenticated.
  User? get currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges;

  /// Sign in with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Create a new account with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign in with Google OAuth.
  /// Returns null if the user cancels the flow.
  Future<UserCredential?> signInWithGoogle();

  /// Sign out from Firebase (and Google if applicable).
  Future<void> signOut();
}
