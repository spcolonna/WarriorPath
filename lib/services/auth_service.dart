import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicia sesión con Google. Devuelve el [User] o null si el usuario cancela.
  /// No escribe en Firestore: el caller llama a navigateAfterAuth, que crea el
  /// documento si falta (el mail de Google ya viene verificado).
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // cancelado por el usuario
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  /// Inicia sesión con Apple usando el flujo nativo gestionado por Firebase.
  ///
  /// Se usa `signInWithProvider(AppleAuthProvider)` en vez de construir la
  /// credencial a mano con `OAuthProvider('apple.com').credential(...)`:
  /// diagnosticamos que el token de Apple era válido y el backend lo aceptaba
  /// vía REST, pero el camino manual fallaba con "Invalid OAuth response from
  /// apple.com". Este método deja que Firebase maneje token/nonce internamente.
  Future<User?> signInWithApple() async {
    final appleProvider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    try {
      final userCredential = await _auth.signInWithProvider(appleProvider);
      _debugApple('signInWithProvider OK, uid=${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      _debugApple('FirebaseAuthException code=${e.code} message=${e.message}');
      rethrow;
    }
  }

  // Helper de diagnóstico (temporal, quitar antes del release).
  void _debugApple(String msg) => debugPrint('APPLE_SIGNIN: $msg');

  /// Elimina por completo la cuenta del usuario actual: sus datos en Firestore
  /// (membresías, hijos, guardianías, documento de usuario) y la cuenta de
  /// Firebase Auth, todo del lado servidor para no depender del login reciente.
  /// Cumple con la Guideline 5.1.1(v) de la App Store.
  Future<void> deleteAccount() async {
    final callable = FirebaseFunctions.instance.httpsCallable('deleteMyAccount');
    await callable.call();
    await _auth.signOut();
  }

  /// Crea la cuenta de autenticación y envía el correo de verificación.
  /// IMPORTANTE: NO escribe el documento en Firestore todavía. El documento
  /// `users/{uid}` recién se crea cuando el usuario confirma su mail y entra
  /// (ver WelcomeScreen._navigateAfterAuth). Así, cuentas sin verificar no
  /// ensucian la base (anti-spam). Devuelve el User de Firebase Auth.
  Future<User> signUpWithEmailPassword(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user!;
    await user.sendEmailVerification();
    return user;
  }

  // Nueva función para obtener el perfil del usuario
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromSnap(userDoc);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
