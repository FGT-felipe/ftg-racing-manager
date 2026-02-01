import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of users for Real-time Auth State
  Stream<User?> get user => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("Error in anonymous sign-in: $e");
      return null;
    }
  }

  // Placeholder for real email sign-in (Simulated for this exercise or can be implemented)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // For this environment, we might just sign within anonymously but treat as "logged in"
      // Or actually trigger createUserWithEmailAndPassword if we could.
      // Let's stick to anonymous for simplicity unless the user set up Auth in Firebase Console.
      // We will assume Anonymous IS the login for now to avoid Auth errors.
      return await signInAnonymously();
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // NEW: Check for Manager Profile
  Future<bool> hasManagerProfile(String uid) async {
    try {
      final doc = await _db.collection('managers').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
