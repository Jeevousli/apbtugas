import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// Handles all remote Firebase Auth and Firestore operations.
class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  CollectionReference get _usersCollection => _firestore.collection('users');

  // ─────────────────────── LOGIN WITH EMAIL ───────────────────────
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      return await _getUserFromFirestore(uid);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ─────────────────────── LOGIN WITH NIK ─────────────────────────
  Future<UserModel> loginWithNik({
    required String nik,
    required String password,
  }) async {
    try {
      // Step 1: Query Firestore to find email by NIK
      final query = await _usersCollection
          .where('nik', isEqualTo: nik.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw const AuthFailure('NIK tidak terdaftar dalam sistem');
      }

      final userData = query.docs.first.data() as Map<String, dynamic>;
      final email = userData['email'] as String?;

      if (email == null || email.isEmpty) {
        throw const AuthFailure('Akun tidak memiliki email yang terdaftar');
      }

      // Step 2: Login with found email
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      return await _getUserFromFirestore(uid);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ─────────────────────── GET USER ───────────────────────────────
  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) {
      throw const AuthFailure('Data pengguna tidak ditemukan di sistem');
    }
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    try {
      return await _getUserFromFirestore(firebaseUser.uid);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────── FORGOT PASSWORD ────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  // ─────────────────────── LOGOUT ─────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─────────────────────── AUTH STATE ─────────────────────────────
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return getCurrentUser();
    });
  }

  // ─────────────────────── FCM TOKEN ──────────────────────────────
  Future<void> updateFcmToken(String uid, String token) async {
    await _usersCollection.doc(uid).update({'fcmToken': token});
  }

  // ─────────────────────── CREATE USER (Admin) ────────────────────
  Future<UserModel> createEmployeeAccount({
    required String email,
    required String password,
    required String name,
    required String nik,
  }) async {
    FirebaseApp? tempApp;
    try {
      // Create a temporary FirebaseApp to prevent logging out current admin
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Create auth user using temp auth
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      // Save to Firestore using primary Firestore instance
      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email.trim(),
        nik: nik.trim(),
        role: UserRole.employee,
        createdAt: DateTime.now(),
      );
      await _usersCollection.doc(uid).set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  // ─────────────────────── PROFILE MANAGEMENT ───────────────────────
  Future<UserModel> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isEmpty) {
        return await _getUserFromFirestore(uid);
      }

      await _usersCollection.doc(uid).update(updates);
      return await _getUserFromFirestore(uid);
    } catch (e) {
      throw AuthFailure('Gagal memperbarui profil: $e');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthFailure('Pengguna tidak terautentikasi');
      }

      // Re-authenticate user first
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure('Gagal mengubah password: $e');
    }
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw const AuthFailure('File foto tidak ditemukan');
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$uid.jpg');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Fallback to base64 if storage is not configured/accessible
      try {
        final file = File(filePath);
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64String';
      } catch (innerErr) {
        throw AuthFailure('Gagal mengupload foto profil: $e');
      }
    }
  }

  // ─────────────────────── ERROR MAPPING ──────────────────────────
  AuthFailure _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthFailure('Akun tidak ditemukan');
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Email/NIK atau password salah');
      case 'invalid-email':
        return const AuthFailure('Format email tidak valid');
      case 'user-disabled':
        return const AuthFailure('Akun Anda telah dinonaktifkan');
      case 'too-many-requests':
        return const AuthFailure(
            'Terlalu banyak percobaan. Coba beberapa saat lagi.');
      case 'network-request-failed':
        return const AuthFailure('Koneksi internet bermasalah');
      case 'email-already-in-use':
        return const AuthFailure('Email sudah terdaftar');
      case 'weak-password':
        return const AuthFailure('Password terlalu lemah (minimal 6 karakter)');
      default:
        return AuthFailure('Terjadi kesalahan: ${e.message}');
    }
  }
}
