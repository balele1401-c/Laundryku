import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/enums.dart';

/// Status autentikasi aplikasi.
enum AuthState {
  /// Belum diketahui (sedang cek).
  unknown,

  /// Belum login.
  unauthenticated,

  /// Sudah login, tapi data user dari Firestore belum siap.
  authenticatedLoading,

  /// Sudah login dan data user sudah tersedia.
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  AuthState _authState = AuthState.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Constructor ─────────────────────────────────────────────────────

  AuthProvider() {
    _checkCurrentUser();
  }

  // ─── Getters ──────────────────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  AuthState get authState => _authState;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _authState == AuthState.authenticated;
  String? get errorMessage => _errorMessage;
  User? get firebaseUser => _auth.currentUser;

  // ─── Initial Check ──────────────────────────────────────────────────

  /// Cek apakah ada user yang masih login (cold start / refresh).
  Future<void> _checkCurrentUser() async {
    await Future.delayed(Duration.zero);

    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('🔑 Firebase user terdeteksi: ${user.email} (UID: ${user.uid})');
      _authState = AuthState.authenticatedLoading;
      notifyListeners();

      final success = await _fetchUserData(user.uid);
      _authState =
          success ? AuthState.authenticated : AuthState.unauthenticated;
    } else {
      debugPrint('ℹ️ Tidak ada sesi user aktif.');
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // ─── Login ────────────────────────────────────────────────────────────

  /// Login dengan email & password, lalu ambil data user dari Firestore.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🚀 Mencoba login dengan email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _setError('Login gagal. Silakan coba lagi.');
        _authState = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      debugPrint('✅ Firebase Auth login berhasil untuk UID: ${user.uid}');

      // Ambil data user dari Firestore
      _authState = AuthState.authenticatedLoading;
      notifyListeners();

      final success = await _fetchUserData(user.uid);
      if (success) {
        _authState = AuthState.authenticated;
        debugPrint('🎉 Login lengkap, beralih ke Dashboard!');
      } else {
        _authState = AuthState.unauthenticated;
      }
      notifyListeners();
      return success;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: [${e.code}] ${e.message}');
      _setError(_mapAuthError(e.code));
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected Login Error: $e');
      _setError('Terjadi kesalahan: ${e.toString()}');
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────

  /// Registrasi user baru (Owner / Kasir) ke Firebase Auth & Firestore `users`.
  Future<bool> register({
    required String email,
    required String password,
    required String nama,
    required UserRole role,
    String? laundryName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🚀 Mendaftarkan user baru: $email (Role: ${role.name})');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _setError('Registrasi gagal. Silakan coba lagi.');
        _authState = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      final cleanLaundryId = laundryName != null && laundryName.trim().isNotEmpty
          ? laundryName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')
          : 'laundry_main';

      final newUser = UserModel(
        uid: user.uid,
        nama: nama.trim(),
        role: role,
        laundryId: cleanLaundryId,
      );

      // Simpan dokumen user ke Firestore
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      debugPrint('✅ User profile berhasil disimpan ke Firestore: users/${user.uid}');

      _currentUser = newUser;
      _authState = AuthState.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException saat register: [${e.code}] ${e.message}');
      _setError(_mapAuthError(e.code));
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected Register Error: $e');
      _setError('Terjadi kesalahan: ${e.toString()}');
      _authState = AuthState.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Fetch User Data ─────────────────────────────────────────────────

  /// Ambil data user (role, nama, dll) dari Firestore collection `users`.
  Future<bool> _fetchUserData(String uid) async {
    try {
      debugPrint('🔍 Mengambil data Firestore users/$uid ...');
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('⚠️ Dokumen users/$uid belum ada di Firestore.');
        final email = _auth.currentUser?.email ?? '';
        final defaultNama = email.isNotEmpty ? email.split('@')[0] : 'User';

        final defaultUser = UserModel(
          uid: uid,
          nama: defaultNama,
          role: UserRole.owner, // default ke owner agar bisa akses dashboard
          laundryId: 'laundry_default',
        );

        try {
          debugPrint('📝 Mencoba membuat profil default di Firestore...');
          await _firestore
              .collection('users')
              .doc(uid)
              .set(defaultUser.toMap());
          debugPrint('✅ Profil default berhasil disimpan di Firestore.');
        } catch (createErr) {
          debugPrint('⚠️ Gagal menyimpan ke Firestore: $createErr');
        }

        _currentUser = defaultUser;
        return true;
      }

      _currentUser = UserModel.fromFirestore(doc);
      debugPrint('✅ Profil user berhasil dimuat: nama=${_currentUser?.nama}, role=${_currentUser?.role.name}');
      return true;
    } catch (e) {
      debugPrint('⚠️ Error saat get user Firestore: $e');
      final email = _auth.currentUser?.email ?? '';
      final defaultNama = email.isNotEmpty ? email.split('@')[0] : 'User';
      _currentUser = UserModel(
        uid: uid,
        nama: defaultNama,
        role: UserRole.owner,
        laundryId: 'laundry_default',
      );
      return true;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────

  Future<void> logout() async {
    _setLoading(true);
    try {
      debugPrint('🚪 Melakukan logout...');
      await _auth.signOut();
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      notifyListeners();
      debugPrint('✅ Berhasil logout.');
    } catch (e) {
      debugPrint('❌ Gagal logout: $e');
      _setError('Gagal logout: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Map Firebase Auth error code ke pesan ramah pengguna (Bahasa Indonesia).
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan. Periksa email Anda.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan login atau gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      default:
        return 'Autentikasi gagal. Silakan coba lagi. ($code)';
    }
  }
}
