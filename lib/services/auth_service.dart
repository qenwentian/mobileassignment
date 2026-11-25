import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/user_model.dart';

class AuthService {
  static const demoCode = '123456';
  static const demoEmail = 'demo@univ.edu';
  static const demoPassword = 'campus123';

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _authOverride = auth,
        _dbOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _dbOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  bool get hasCurrentUser => _authOverride != null
      ? _authOverride.currentUser != null
      : (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null);

  Stream<String?> authUidChanges() {
    if (_authOverride == null && Firebase.apps.isEmpty) {
      return const Stream<String?>.empty();
    }
    return _auth.authStateChanges().map((u) => u?.uid);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    if (_dbOverride == null && Firebase.apps.isEmpty) {
      return const Stream<UserModel?>.empty();
    }
    return _users.doc(uid).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? UserModel.fromFirestore(doc)
              : null,
        );
  }

  Future<UserModel> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Incorrect email or password.');
      }
      return await _ensureUserProfile(firebaseUser);
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<UserModel> verifyAndRegister({
    required String studentId,
    required String name,
    required String email,
    required String password,
    required String code,
  }) async {
    if (code != demoCode) throw Exception('Invalid verification code.');
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim();
    final trimmedStudentId = studentId.trim();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Could not create user account.');
      }
      try {
        await firebaseUser.updateDisplayName(trimmedName);
        final profile = UserModel(
          id: firebaseUser.uid,
          studentId: trimmedStudentId,
          name: trimmedName,
          email: normalizedEmail,
          role: UserRole.normal,
        );
        await _users.doc(firebaseUser.uid).set({
          ...profile.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        return profile;
      } catch (_) {
        // Avoid leaving an orphaned Auth user if profile creation fails.
        try {
          await firebaseUser.delete();
        } catch (_) {}
        rethrow;
      }
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> logout() async {
    if (_authOverride == null && Firebase.apps.isEmpty) return;
    try {
      await _auth.signOut();
    } catch (error) {
      throw _mapError(error);
    }
  }

  Stream<List<UserModel>> watchAllUsers() {
    if (_dbOverride == null && Firebase.apps.isEmpty) {
      return const Stream<List<UserModel>>.empty();
    }
    return _users.snapshots().map((snapshot) {
      final list = snapshot.docs.map(UserModel.fromFirestore).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      await _users.doc(uid).update({'role': role.value});
    } catch (error) {
      throw _mapError(error);
    }
  }

  Future<UserModel> _ensureUserProfile(User firebaseUser) async {
    final docRef = _users.doc(firebaseUser.uid);
    final snapshot = await docRef.get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromFirestore(snapshot);
    }
    final email = (firebaseUser.email ?? '').trim().toLowerCase();
    final rawName = (firebaseUser.displayName ?? '').trim();
    final fallbackName = email.contains('@') ? email.split('@').first : 'Student';
    final name = rawName.isNotEmpty
        ? rawName
        : (fallbackName.isNotEmpty ? fallbackName : 'Student');
    final clampedName = name.length > 100 ? name.substring(0, 100) : name;
    final profile = UserModel(
      id: firebaseUser.uid,
      studentId: '',
      name: clampedName,
      email: email,
      role: UserRole.normal,
    );
    await docRef.set({
      ...profile.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return profile;
  }

  Exception _mapError(Object error) {
    if (error is FirebaseAuthException) {
      return Exception(switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already uses that email.',
        'invalid-email' => 'Enter a valid campus email.',
        'weak-password' => 'Use a password with at least 6 characters.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'network-request-failed' =>
          'Network error. Check your connection and try again.',
        _ => error.message ?? 'Authentication failed.',
      });
    }
    if (error is FirebaseException) {
      return Exception(switch (error.code) {
        'permission-denied' =>
          'Permission denied. Check your role or Firestore security rules.',
        'unavailable' || 'deadline-exceeded' =>
          'Cannot reach Cloud Firestore. Check your connection and try again.',
        'no-app' => 'Firebase is not configured yet.',
        _ => error.message ?? 'Could not access account records.',
      });
    }
    if (error is Exception) return error;
    return Exception('Could not complete authentication.');
  }
}
