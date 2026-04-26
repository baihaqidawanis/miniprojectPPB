import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan stream user terkini
  Stream<User?> get userStream => _auth.authStateChanges();

  // Mendapatkan User saat ini
  User? get currentUser => _auth.currentUser;

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Anonymous Login
  Future<void> loginAnonymous() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      rethrow;
    }
  }

  // Register
  Future<UserModel?> register(
    String email,
    String password,
    String name, {
    String role = 'user',
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: name,
          role: role,
          userSettings: {'notificationsEnabled': true, 'prefersDarkMode': true},
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get Data User spesifik
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error fetching user data: \$e");
      return null;
    }
  }
}
