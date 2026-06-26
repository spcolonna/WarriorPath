import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Elimina por completo la cuenta del usuario actual: sus datos en Firestore
  /// (membresías, hijos, guardianías, documento de usuario) y la cuenta de
  /// Firebase Auth, todo del lado servidor para no depender del login reciente.
  /// Cumple con la Guideline 5.1.1(v) de la App Store.
  Future<void> deleteAccount() async {
    final callable = FirebaseFunctions.instance.httpsCallable('deleteMyAccount');
    await callable.call();
    await _auth.signOut();
  }

  Future<UserModel?> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Creamos el modelo para el nuevo usuario
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email!,
          wizardStep: 0, // ¡Importante! Iniciamos el wizard
        );

        // Guardamos el nuevo usuario en la colección 'users'
        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
        return newUser;
      }
      return null;
    } catch (e) {
      // Maneja errores (ej. email en uso)
      print(e.toString());
      return null;
    }
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
