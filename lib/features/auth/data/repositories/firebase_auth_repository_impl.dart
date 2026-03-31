import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] backed by Firebase Auth
/// and Google Sign-In. Keep all Firebase-specific logic in this file.
class FirebaseAuthRepositoryImpl implements AuthRepository {
  FirebaseAuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        // On Web, GoogleSignIn.instance is not pre-initialized (no clientId meta
        // tag configured yet), so we fall back gracefully.
        _googleSignIn = googleSignIn ?? (kIsWeb ? null : GoogleSignIn.instance);

  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn; // nullable — null on Web until configured

  // ── Getters ──────────────────────────────────────────────────────────────

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password ──────────────────────────────────────────────────────

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  @override
  Future<UserCredential?> signInWithGoogle() async {
    // Web: Google Sign-In via popup (Firebase Auth native web flow).
    // This avoids the google_sign_in package entirely on web — more reliable.
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      // Add scopes as needed
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return _auth.signInWithPopup(googleProvider);
    }

    // Mobile (Android / iOS):
    // google_sign_in v7.0.0+ uses authenticate() instead of signIn()
    if (_googleSignIn == null) return null;

    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    if (kIsWeb) {
      await _auth.signOut();
      return;
    }
    await Future.wait([
      _auth.signOut(),
      if (_googleSignIn != null) _googleSignIn.signOut(),
    ]);
  }
}
