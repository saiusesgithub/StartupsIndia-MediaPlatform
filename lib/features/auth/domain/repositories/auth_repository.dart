import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

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

  /// Returns the active user data for profile UI.
  Future<UserModel?> getCurrentUserModel();

  /// Persists user profile information into Firestore users/{uid}.
  Future<void> saveUserData(UserModel user);

  /// Updates user profile fields from edit-profile form.
  Future<void> updateUserData(UserModel updatedUser);

  /// Sends a Firebase password-reset email to [email].
  /// Throws [FirebaseAuthException] on failure.
  Future<void> sendPasswordResetEmail(String email);

  /// Fetches the sign-in methods registered for [email].
  /// Returns an empty list if the email is not registered.
  Future<List<String>> fetchSignInMethodsForEmail(String email);
}
