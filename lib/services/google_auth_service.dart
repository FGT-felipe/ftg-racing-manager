import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signIn() async {
    try {
      // 1. Iniciar el flujo interactivo
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // En web a veces requiere forzar el popup si hay cookies previas
        googleUser = await _googleSignIn.signInSilently();
      }

      // Si no logró entrar silenciosamente o es móvil, forzar popup
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        print("El usuario canceló el login");
        return null;
      }

      // 2. Obtener detalles de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear credencial nueva para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      // 5. Lógica de Base de Datos (Crear User si no existe)
      if (user != null) {
        await _saveUserToFirestore(user);
      }

      return user;
    } catch (e) {
      print("ERROR CRÍTICO GOOGLE SIGN IN: $e");
      rethrow;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      // Crear documento limpio
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'firstName': user.displayName?.split(' ').first ?? '',
        'lastName': user.displayName?.split(' ').last ?? '',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
