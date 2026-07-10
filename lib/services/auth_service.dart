import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  /// Inicia sesión con Apple (Sign in with Apple). Devuelve el [User].
  Future<User?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple solo entrega el nombre en el primer login; lo guardamos en Auth.
    final user = userCredential.user;
    if (user != null &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      final given = appleCredential.givenName ?? '';
      final family = appleCredential.familyName ?? '';
      final fullName = '$given $family'.trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }
    }
    return user;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

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
