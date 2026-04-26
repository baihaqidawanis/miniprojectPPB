import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.userStream.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        // Tidak ada session aktif → auto login sebagai anonymous
        _autoLoginAnonymous();
        return;
      }

      if (firebaseUser.isAnonymous) {
        _userModel = UserModel(
          uid: firebaseUser.uid,
          email: 'guest@anonymous',
          displayName: 'Pengunjung',
          role: 'guest',
        );
        notifyListeners();
        return;
      }

      // Jika sudah ada data untuk user ini (set oleh login/register), jangan overwrite.
      // Ini mencegah race condition saat register (listener fire sebelum Firestore doc selesai ditulis).
      if (_userModel != null && _userModel!.uid == firebaseUser.uid) {
        notifyListeners();
        return;
      }

      // App restart atau login baru: ambil dari Firestore
      final userData = await _authService.getUserData(firebaseUser.uid);
      // Fallback jika Firestore doc belum ada / permission issue
      _userModel = userData ??
          UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.email?.split('@').first ?? 'User',
            role: 'user',
          );
      notifyListeners();
    });
  }

  Future<void> _autoLoginAnonymous() async {
    try {
      await _authService.loginAnonymous();
    } catch (_) {
      // Jika anonymous login gagal, tetap set guest model lokal
      _userModel = UserModel(
        uid: 'local_guest',
        email: 'guest@anonymous',
        displayName: 'Pengunjung',
        role: 'guest',
      );
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _userModel = await _authService.login(email, password);
      // Fallback jika getUserData() gagal (Firestore rules / network)
      if (_userModel == null && _authService.currentUser != null) {
        _userModel = UserModel(
          uid: _authService.currentUser!.uid,
          email: email,
          displayName: email.split('@').first,
          role: 'user',
        );
      }
      _setLoading(false);
      return _userModel != null;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    _setLoading(true);
    try {
      await _authService.loginAnonymous();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, {String role = 'user'}) async {
    _setLoading(true);
    try {
      // Set langsung dari hasil register agar listener tidak overwrite dengan null
      _userModel = await _authService.register(email, password, name, role: role);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    // Setelah logout, langsung login anonymous lagi (kembali jadi guest)
    // _init() listener akan menangkap event signOut dan auto re-login
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
