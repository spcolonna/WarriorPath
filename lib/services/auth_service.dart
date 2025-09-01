import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
