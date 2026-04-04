import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provides the [AuthRepository] (backed by Firebase) to the app.
/// Screens and other providers import this — never the impl directly.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseAuthRepositoryImpl(
    firebaseAuth: firebaseAuth,
    firebaseFirestore: firestore,
  );
});
