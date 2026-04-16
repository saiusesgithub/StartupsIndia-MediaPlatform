import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] backed by Firebase Auth
/// and Google Sign-In. Keep all Firebase-specific logic in this file.
class FirebaseAuthRepositoryImpl implements AuthRepository {
  FirebaseAuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firebaseFirestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firebaseFirestore ?? FirebaseFirestore.instance,
       // On Web, GoogleSignIn.instance is not pre-initialized (no clientId meta
       // tag configured yet), so we fall back gracefully.
       _googleSignIn = googleSignIn ?? (kIsWeb ? null : GoogleSignIn.instance);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
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

  @override
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const UserModel(
        uid: 'demo_user',
        username: 'wilsonfranci',
        fullName: 'Wilson Franci',
        email: 'wilson@example.com',
        phone: '+62-8421-4512-2531',
        displayName: 'Wilson Franci',
        bio:
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        avatarUrl: 'assets/images/thumb_politics.png',
        websiteUrl: 'https://example.com',
        followersCount: 2156,
        followingCount: 567,
        newsCount: 23,
      );
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    final fallback = UserModel(
      uid: user.uid,
      username: user.email?.split('@').first ?? 'newscreator',
      fullName: (user.displayName == null || user.displayName!.trim().isEmpty)
          ? 'News Creator'
          : user.displayName!.trim(),
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      displayName:
          (user.displayName == null || user.displayName!.trim().isEmpty)
          ? 'News Creator'
          : user.displayName!.trim(),
      bio: 'Sharing updates and insights from around the world.',
      avatarUrl: user.photoURL ?? 'assets/images/thumb_politics.png',
      websiteUrl: 'https://example.com',
      followersCount: 2156,
      followingCount: 567,
      newsCount: 23,
    );

    await saveUserData(fallback);
    return fallback;
  }

  @override
  Future<void> saveUserData(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> updateUserData(UserModel updatedUser) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await user.updateDisplayName(updatedUser.fullName.trim());

    if (updatedUser.email.trim().isNotEmpty &&
        updatedUser.email.trim() != (user.email ?? '')) {
      try {
        await user.verifyBeforeUpdateEmail(updatedUser.email.trim());
      } on FirebaseAuthException {
        // Ignore for now if recent login is required; UI remains responsive.
      }
    }

    final merged = updatedUser.copyWith(
      uid: user.uid,
      displayName: updatedUser.fullName.trim().isEmpty
          ? updatedUser.displayName
          : updatedUser.fullName.trim(),
      avatarUrl: updatedUser.avatarUrl.isEmpty
          ? (user.photoURL ?? updatedUser.avatarUrl)
          : updatedUser.avatarUrl,
    );

    await saveUserData(merged);
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }
}
