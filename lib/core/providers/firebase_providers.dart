import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton FirebaseAuth instance across the entire app.
/// Import this wherever you need to access Auth state.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Stream provider that exposes the current authenticated [User].
/// Widgets or other providers can watch this to react to auth changes.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});
