import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para detectar cambios de sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get user =>
      _auth.authStateChanges(); // Alias to fix existing usage

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Sign In Anonymously (Restore functionality)
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("Error in anonymous sign-in: $e");
      return null;
    }
  }

  // LOGIN CON GOOGLE
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger del Popup Nativo
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuario canceló

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 2. Credenciales para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Login en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // 4. Verificar si existe en la colección 'users' (NO managers)
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // 5. Crear usuario nuevo si es la primera vez
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'firstName': user.displayName?.split(' ').first ?? 'Driver',
            'lastName': user.displayName?.split(' ').last ?? '',
            'registrationDate': DateTime.now().toIso8601String(),
          });
        }
      }
      return user;
    } catch (e) {
      print("Error en Google Sign In: $e");
      return null;
    }
  }

  // REGISTRO CON EMAIL
  Future<User?> registerWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'registrationDate': DateTime.now().toIso8601String(),
        });
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // LOGIN CON EMAIL
  Future<User?> signInWithEmail(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get App User Data
  Future<AppUser?> getAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching AppUser: $e");
      return null;
    }
  }

  // Get Manager Profile
  Future<ManagerProfile?> getManagerProfile(String uid) async {
    try {
      final doc = await _firestore.collection('managers').doc(uid).get();
      if (doc.exists) {
        return ManagerProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching ManagerProfile: $e");
      return null;
    }
  }
}
